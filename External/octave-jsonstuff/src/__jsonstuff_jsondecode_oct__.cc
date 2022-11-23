/*
Copyright (C) 2019 Andrew Janke <floss@apjanke.net>

This file is part of Octave.

Octave is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Octave is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Octave; see the file COPYING.  If not, see
<https://www.gnu.org/licenses/>.
*/

#include <cmath>
#include <iostream>
#include <sstream>

#include <octave/oct.h>
#include "rapidjson/document.h"
#include "rapidjson/stringbuffer.h"

using namespace rapidjson;

// Inputs:
//   1: Encoded JSON data as char vector
// Outputs:
//   1: Decoded value as Octave value

class decode_result {
public:
  octave_value value;
  bool is_condensed;
  decode_result (const NDArray &val)
    : value (octave_value (val)), is_condensed (false) {}
  decode_result (const int64NDArray &val)
    : value (octave_value (val)), is_condensed (false) {}
  decode_result (const uint64NDArray &val)
    : value (octave_value (val)), is_condensed (false) {}
  decode_result (const octave_value &val)
    : value (val), is_condensed (false) {}
  decode_result (const octave_value &val, bool condensed)
    : value (val), is_condensed (condensed) {}
};

decode_result
decode_recursive (const Value &jval);

bool
equals (const string_vector &a, const string_vector &b) {
  if (a.numel () != b.numel ()) {
    return false;
  }
  octave_idx_type n = a.numel ();
  for (octave_idx_type i = 0; i < n; i++) {
    if (a(i) != b(i)) {
      return false;
    }
  }
  return true;
}

decode_result
decode_array (const Value &jval) {
  assert (jval.IsArray ());

  // Decode all the elements first, and then decide how to combine them,
  // based on the set of element types.
  
  // Check for homogeneity
  // Note: JSON nulls must be considered double candidates, but not int64 or uint64
  bool is_first_element = true;
  bool is_homogeneous_numeric = true;
  bool is_all_double = true;
  bool is_all_int64 = true;
  bool is_all_uint64 = true;
  Type type = kNullType;
  for (const Value& val : jval.GetArray ()) {
    Type el_type = val.GetType ();
    if (el_type == kNumberType) {
      if (!val.IsLosslessDouble ())
        is_all_double = false;
      if (!val.IsInt64 ())
        is_all_int64 = false;
      if (!val.IsUint64 ())
        is_all_uint64 = false;
      if (!(is_all_double || is_all_int64 || is_all_uint64)) {
        // No longer a candidate for homogeneous numeric
        is_homogeneous_numeric = false;
        break;
      }
    } else if (el_type == kNullType) {
      is_all_int64 = is_all_uint64 = false;
      if (!(is_all_double || is_all_int64 || is_all_uint64)) {
        // No longer a candidate for homogeneous numeric
        is_homogeneous_numeric = false;
        break;
      }
    } else {
      is_homogeneous_numeric = false;
      is_all_double = is_all_int64 = is_all_uint64 = false;
      break;
    }
  }
  // Fast-decode homogeneous numeric arrays
  if (is_homogeneous_numeric) {
    int num_elems = jval.Capacity ();
    if (num_elems == 0) {
      // Special case: empty numerics are [], not 1-by-0
      return NDArray (dim_vector (0, 0));
    } else {
      if (is_all_double) {
        NDArray out (dim_vector (num_elems, 1));
        for (int i = 0; i < num_elems; i++) {
          if (jval[i].IsNull ()) {
            out(i) = NAN;
          } else {
            out(i) = jval[i].GetDouble ();
          }
        }
      	return out;
      } else if (is_all_int64) {
        int64NDArray out (dim_vector (num_elems, 1));
        for (int i = 0; i < num_elems; i++) {
          out(i) = jval[i].GetInt64 ();
        }
      	return out;
      } else if (is_all_uint64) {
        uint64NDArray out (dim_vector (num_elems, 1));
        for (int i = 0; i < num_elems; i++) {
          out(i) = jval[i].GetUint64 ();
        }
      	return out;
      } else {
        error ("Internal error: detected homogeneous numeric array, but none of the number formats fit.");
      }
    }
  } else {
    bool is_any_child_condensed = false;
    bool is_all_child_structs = true;
    int num_children = jval.Capacity ();
  	Cell children (dim_vector (num_children, 1));
  	for (int i = 0; i < num_children; i++) {
  	  auto rslt = decode_recursive (jval[i]);
  	  is_all_child_structs &= rslt.value.isstruct ();
  	  is_any_child_condensed |= rslt.is_condensed;
  	  children(i) = rslt.value;
  	}
    return octave_value (children);
  }
}

decode_result
decode_object (const Value &jval) {
  octave_scalar_map s;
  for (Value::ConstMemberIterator it = jval.MemberBegin (); it != jval.MemberEnd (); it++) {
    std::string name = it->name.GetString ();
    decode_result oct_val = decode_recursive (it->value);
    s.assign (name, oct_val.value);
  }
  return octave_value (s);
}

decode_result
decode_string (const Value &jval) {
  return octave_value (jval.GetString ());
}

decode_result
decode_boolean (const Value &jval) {
  boolNDArray out = boolNDArray (dim_vector (1, 1));
  out(0) = jval.GetBool ();
  return octave_value (out);
}

decode_result
decode_null (const Value &jval) {
  NDArray out (dim_vector (0, 0));
  return out;
}

decode_result
decode_number (const Value &jval) {
  if (jval.IsLosslessDouble ()) {
    NDArray out (dim_vector (1, 1));
    out(0) = jval.GetDouble ();
    return out;
  } else if (jval.IsInt64 ()) {
    int64NDArray out (dim_vector (1, 1));
    out(0) = jval.GetInt64 ();
    return out;
  } else if (jval.IsUint64 ()) {
    uint64NDArray out (dim_vector (1, 1));
    out(0) = jval.GetUint64 ();
    return out;
  } else {
    // TODO: Include the JSON text of the number in the error message
    error ("Internal error: Number was not representable as double, int64, or uint64");
  }
}

decode_result
decode_recursive (const Value &jval) {
  Type type = jval.GetType ();
  switch (type) {
    case kNullType:
      return decode_null (jval);
      break;
    case kNumberType:
      return decode_number (jval);
      break;
    case kStringType:
      return decode_string (jval);
      break;
    case kTrueType:
    case kFalseType:
      return decode_boolean (jval);
      break;
    case kArrayType:
      return decode_array (jval);
      break;
    case kObjectType:
      return decode_object (jval);
      break;
  }
  // This shouldn't happen
  // TODO: include the type name in the error message
  error ("Internal error: Unimplemented JSON type");
}

decode_result
decode_json_text (const std::string &json_str) {
  Document document;
  document.Parse (json_str.c_str ());
  if (document.HasParseError ()) {
    // TODO: Include details about the parsing failure. Use GetParseError().
    error ("JSON parsing error (no details available; sorry)");
  }
  return decode_recursive (document);
}

DEFUN_DLD (__jsonstuff_jsondecode_oct__, args, nargout,
  "Decode JSON text to Octave value\n"
  "\n"
  "-*- texinfo -*-\n"
  "@deftypefn {Function File} {@var{out} =} __jsonstuff_jsondecode_oct__ (@var{json_text})\n"
  "\n"
  "Undocumented internal function for jsonstuff package.\n"
  "\n"
  "@end deftypefn\n")
{
  octave_idx_type nargin = args.length ();
  if (nargin != 1) {
    error ("Invalid number of arguments: expected 1; got %ld", (long) nargin);
  }

  octave_value json_text_ov = args(0);
  builtin_type_t json_text_ov_type = json_text_ov.builtin_type ();
  if (json_text_ov_type != btyp_char) {
    error ("Error: unsupported input data type: expected char");
  }

  std::string json_str = json_text_ov.string_value ();
  decode_result decoded = decode_json_text (json_str);
  return decoded.value;
}