## Copyright (C) 2019 Andrew Janke <floss@apjanke.net>
##
## This file is part of Octave.
##
## Octave is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <https://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn  {Function} {@var{value} =} jsondecode (@var{text})
## @deftypefnx {Function} {@var{value} =} jsondecode (@var{text})
##
## Decode a JSON document into Octave data.
##
## Decodes a string @var{text} containing a JSON document into a native Octave
## data structure equivalent.
##
## @var{text} must be a char vector containing a valid JSON document. It is an
## error if any other type of input is passed, or if the char vector does not contain
## a valid JSON document.
##
## The conversion from the JSON data model to native Octave data is performed as
## follows:
##
## @itemize @bullet
## @item
## JSON numbers are converted to Octave doubles.
##
## @item
## JSON strings are converted to Octave char vectors.
##
## @item
## JSON objects are converted to scalar Octave structs.
##
## @item
## JSON arrays are converted co Octave cell vectors.
##
## @item
## JSON arrays whose contained elements are all of the same type are "condensed"
## using a somewhat complicated, currently undocumented algorithm. This condensation
## process converts arrays containing numbers into numeric arrays (instead of cell
## arrays), and may convert arrays of arrays into multidimensional arrays (instead
## of nested cell arrays).
##
## @end itemize
##
## @xref{jsonencode}
##
## @end deftypefn

function out = jsondecode (text)
  data = __jsonstuff_jsondecode_oct__ (text);
  out = condense_decoded_json (data);
endfunction

function out = condense_decoded_json (x)
  out = condense_decoded_json_recursive (x);
endfunction

function out = condense_decoded_json_recursive (x)
  if ~iscell (x)
    out = x;
    return
  endif
  if isempty (x)
    out = x;
    return
  endif
  x_in = x; % for debugging

  % Depth-first: condense the component arrays first
  for i = 1:numel (x)
    x{i} = condense_decoded_json_recursive (x{i});
    % Permute/"Rotate" all child values up 1 dimension
    % We need to do the rotation here, because it happens regardless of whether
    % the children actually end up getting condensed together.
    if ~isempty (x{i}) && ~ischar (x{i})
      x{i} = permute (x{i}, [ndims(x{i})+1 1:ndims(x{i})]);
    endif
  endfor
  
  % Struct and arrays are condensable if they have all the same dimensions
  sz = size (x{1});
  is_all_struct = true;
  is_all_numeric = true;
  is_conformant = true;
  for i = 1:numel (x)
    if ~isnumeric (x{i})
      is_all_numeric = false;
    endif
    if ~isstruct (x{i})
      is_all_struct = false;
    endif
    if ~isequal (size (x{i}), sz)
      is_conformant = false;
    endif
    % Check if we can stop looking
    if !is_conformant || (!is_all_struct && !is_all_numeric)
      break
    endif
  endfor

  is_condensable = (is_all_struct || is_all_numeric) && is_conformant && ~isempty(x{1});
  
  if is_condensable
    out = cat (1, x{:});
  else
    out = x;
  endif

endfunction

%!assert (jsondecode ('42'), 42)
%!assert (jsondecode ('"foobar"'), "foobar")
%!assert (jsondecode ('null'), [])
%!assert (jsondecode ('[]'), [])
%!assert (jsondecode ('[[]]'), {[]})
%!assert (jsondecode ('[[[]]]'), {{[]}})
%!assert (jsondecode ('[1, 2, 3]'), [1; 2; 3])
%!assert (jsondecode ('[1, 2, null]'), [1; 2; NaN])
%!assert (jsondecode ('[1, 2, "foo"]'), {1; 2; "foo"})
%!assert (jsondecode ('{"foo": 42, "bar": "hello"}'), struct("foo",42, "bar","hello"))
%!assert (jsondecode ('[{"foo": 42, "bar": "hello"}, {"foo": 1.23, "bar": "world"}]'), struct("foo", {42; 1.23}, "bar", {"hello"; "world"}))
%!assert (jsondecode ('[1, 2]'), [1; 2])
%!assert (jsondecode ('[[1, 2]]'), [1 2])
%!assert (jsondecode ('[[[1, 2]]]'), cat(3, 1, 2))
%!assert (jsondecode ('[[1, 2], [3, 4]]'), [1 2; 3 4])
%!assert (jsondecode ('[[[1, 2], [3, 4]]]'), cat(3, [1 3], [2 4]))
%!assert (jsondecode ('[[[1, 2], [3, 4]], [[5, 6], [7, 8]]]'), cat(3, [1 3; 5 7], [2 4; 6 8]))
%!assert (jsondecode ('{}'), struct)
%!assert (jsondecode ('[{}]'), struct)
%!assert (jsondecode ('[[{}]]'), struct)
%!assert (jsondecode ('[{}, {}]'), [struct; struct])
%!assert (jsondecode ('[[{}, {}]]'), [struct struct])
%!assert (jsondecode ('[[[{}, {}]]]'), cat(3, struct, struct))