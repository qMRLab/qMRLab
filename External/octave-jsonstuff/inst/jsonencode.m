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
## @deftypefn  {Function} {@var{text} =} jsonencode (@var{data})
## @deftypefnx {Function} {@var{text} =} jsonencode (@var{data}, @code{"ConvertInfAndNaN"}, @var{TF})
##
## Encode Octave data as JSON.
##
## Encodes the Octave value @code{data} in JSON format and returns the
## result as a character vector.
##
## @code{jsonencode (..., "ConvertInfAndNaN", TF)} controls the encoding of special floating
## point values NaN, Inf, and -Inf.
##
## @xref{jsondecode}
##
## @end deftypefn

## Note: This implementation contains support for "future" data types that are
## currently unimplemented in Octave (as of Octave 5.0), such as string, 
## categorical, and datetime. This implementation is written against those
## future types' interfaces such that it should Just Work once definitions for
## those types are supplied by Octave or an add-on package, and in the mean time
## it does not call any unimplemented functions, so it is not dependent on those
## definitions being supplied, and works under current Octave.

## TODO: Option for full Matlab compatibility
##   - Needs to ignore object jsonencode() overrides, I think.
## TODO: Option(s) for pretty-printing
## TODO: Option(s) for alternative formatting
##   - ISO 8601 dates
##   - N-D cell arrays instead of flattening to vectors?

function out = jsonencode (data, varargin)
  ## Peel off options
  args = varargin;
  knownOptions = {"ConvertInfAndNaN"};
  opts = struct ("ConvertInfAndNaN", true);
  while numel (args) >= 1 && isa (args{end-1}, "char") ...
      && ismember (args{end-1}, knownOptions)
    opts.(args{end-1}) = args{end};
    args(end-1:end) = [];
  endwhile
  if (! isempty (args))
    error ("jsonencode: Unrecognized options");
  endif
  
  if (! islogical (opts.ConvertInfAndNaN))
    error ("jsonencode: ConvertInfAndNaN argument must be logical; got a %s", ...
      class (opts.ConvertInfAndNaN));
  endif
  
  out = jsonencode_recursive (data);

  function out = jsonencode_recursive (x)
    ## Special-case objects to allow full customization via override methods
    if isobject (x)
      if hasmethod (x, 'jsonencode')
        out = jsonencode (x);
        return
      end
    endif
    ## Empties
    if (isempty (x))
      if (ischar (x))
        out = '""';
      else
        out = "[]";
      endif
      return
    end
    ## Special-case chars because they have weird size semantics
    if (ischar (x))
      if (isrow (x))
        out = json_encode_charvec (x);
        return
      elseif ismatrix (x)
        x = cellstr (x)';
      else
        error ('char arrays greater than 2 dimensions are not supported; got %d dims', ...
          ndims (x));
      endif
    endif
    ## Special-case tables because they have weird size semantics
    if (isa (x, 'table'))
      out = table2struct (x);
    endif
    ## Special-case cells for Matlab compatibility: they are always flattened to vector
    if (iscell (x))
      x = x(:)';
    endif
    ## General case
    if (isscalar (x))
      if islogical (x)
        if (x)
          out = "true";
        else
          out = "false";
        endif
      elseif isnumeric (x)
        out = json_encode_number (x);
      elseif iscell (x)
        out = sprintf("[%s]", jsonencode_recursive (x{1}));
      elseif isstring (x)
        out = json_encode_string (x);
      elseif isstruct (x)
        out = json_encode_struct (x);
      elseif isa (x, 'categorical')
        out = json_encode_categorical (x);
      elseif isa (x, 'containers.Map')
        ## Special case this because it's an object, but doesn't override jsonencode
        out = json_encode_containers_Map (x);
      elseif isa (x, 'datetime')
        ## Special case this because it's an object, but doesn't override jsonencode
        out = json_encode_datetime (x);
      elseif isobject (x)
        ## If we got here, the object does not override jsonencode(); use generic
        out = json_encode_object_generic (x);
      else
        error ("jsonencode: Unsupported data type: %s", class (x));
      endif
    else
      out = json_array_of (x);
    endif    
  endfunction

  function out = json_encode_number (x)
    if ! isscalar (x)
      error ('jsonencode: Internal error: x must be scalar');
    endif
    if isinteger (x)
      out = num2str (x);
    else
      if iscomplex (x)
        error ('jsonencode: Complex numbers are not supported');
      elseif isnan (x) || isinf (x)
        if opts.ConvertInfAndNaN
          out = "null";
        else
          if isinf (x) && x < 0
            out = "-Infinity";
          elseif isinf (x) && x > 0
            out = "Infinity";
          else
            out = "NaN";
          endif
        endif
      elseif isintval (x)
        out = sprintf ("%d", x);
      else
        ## This is the most concise way I could figure out for printing floating
        ## point numbers without roundoff.
        out = sprintf ("%.17e", x);
      end
    endif
  endfunction

  function out = json_encode_charvec (str)
    ## Escapes a scalar string or single charvec
    if (! isrow (str)) 
      error('jsonencode: Internal error: str must be row vector');
    endif
    ## TODO: This is naive and treats input as ASCII-ish. I *think* this is UTF-8
    ## compatible, because no code units that are part of multibyte UTF-8 encodings
    ## fall within the set that we escape (0-20, \b, \t, \f, \r, \n, '"', '\'),
    ## but am not sure. Verify.
    ## TODO: This M-code implementation will be slowish when control characters
    ## are present. Consider replacing it with an oct function.
    c = char (str);
    c = strrep (c, '\', '\\');
    c = strrep (c, '"', '\"');
    if any (c < 20)
      ## Note: this buf logic relies on Octave's in-place assignment optimization.
      junk = "$"; ## Use "$" bc it will be visible when viewing the buf in console.
      initial_capacity = numel (c) * 2;
      buf = repmat (junk, [1 initial_capacity]);
      capacity = numel (buf);
      ix = 1;
      ## Handle special control characters
      function append (chrs)
        if ix == capacity
          buf(end+1:end*2) = junk;
        endif
        buf(ix:ix+numel(chrs)-1) = chrs;
        ix = ix + numel(chrs);
      endfunction
      for i = 1:numel (c)
        if (c(i) < 20)
          ## Special-case common control characters for readability of output
          switch c(i)
            case "\b"
              append ("\b");
            case "\t"
              append ("\t");
            case "\n"
              append ("\n");
            case "\f"
              append ("\f");
            case "\r"
              append ("\r");
            otherwise
              d = double (c(i));
              append (sprintf ('\u%04d', d));
          endswitch
        else
          append (c(i));
        end
      endfor
      c = buf(1:ix-1);
    endif
    out = ['"' c '"'];
  endfunction
  
  function out = json_encode_string (x)
    if ismissing (x)
      out = "null";
    else
      out = json_encode_charvec (char (x));
    endif
  endfunction
  
  function out = json_encode_struct (s)
    fields = fieldnames (s);
    els = cell (1, numel (fields));
    for i = 1:numel (fields)
      field_str = jsonencode_recursive (s.(fields{i}));
      els{i} = sprintf('"%s":%s', fields{i}, field_str);
    endfor
    out = ["{" strjoin(els, ",") "}"];
  endfunction

  function out = json_vector_of (values)
    ## Convert input to a flattened 1-D JSON vector
    strs = cell (1, numel (values));
    for i = 1:numel (values)
      if iscell (values)
        x = values{i};
      else
        x = values(i);
      endif
      strs{i} = jsonencode_recursive (x);
    endfor
    out = strcat ("[", strjoin (strs, ", "), "]");
  endfunction

  function out = json_array_of (values)
    ## Convert input to an N-D nested JSON array
    if isvector (values)
      out = json_vector_of (values);
    elseif ismatrix (values)
      rows = {};
      for i = 1:size (values, 1)
        rows{i} = json_vector_of (values(i,:));
      endfor
      out = strcat ("[", strjoin (rows, ", "), "]");
    else
      ## TODO: implement N-D generalization
      error ("jsonencode: N-D arrays are not supported; input is %d-D", ndims (values));
    end
  endfunction

  function out = json_encode_object_generic (x)
    if ! isscalar (x)
      error ("jsonencode: Internal error: x must be scalar");
    end
    orig_warn = warning;
    warning off Octave:classdef-to-struct
    unwind_protect
      s = struct (x);
    unwind_protect_cleanup
      warning (orig_warn);
    end_unwind_protect
    out = json_encode_struct (s);
  endfunction
  
  function out = json_encode_containers_Map (x)
    nkeys = x.Count;
    els = cell (1, nkeys);
    k = keys (x);
    for i = 1:nkeys
      key = k{i};
      if ~ischar (key)
        error ("jsonencode: only char keys for containers.Map are supported; got a %s key", ...
          class (key));
      endif
      els{i} = sprintf ('%s: %s', json_encode_charvec (key), jsonencode_recursive (x(key)));
    endfor
    out = sprintf ('{%s}', strjoin (els, ","));
  endfunction
  
  function out = json_encode_datetime (x)
    ## Use default datestr format because that's what Matlab does, instead of using
    ## ISO 8601 format like a reasonable person would.
    if isnat (x)
      out = "null";
    else
      out = sprintf ('"%s"', datestr (x));    
    endif
  endfunction
  
  function out = json_encode_categorical (x)
    if isundefined (x)
      out = "null";
    else
      out = json_encode_charvec (char (string (x)));
    endif
  endfunction
end

function out = hasmethod (x, method_name)
  persistent cache
  if isempty (cache)
    cache = containers.Map;
    cache("$$$DUMMY$$$") = "dummy value so the cache isn't isempty()";
  endif
  class_name = class (x);
  if isKey (cache, class_name)
    method_names = cache(class_name);
  else
    ## Can't just use methods (x) because that doesn't work on classdefs
    klass = meta.class.fromName (class (x));
    ## Can't concatenate meta.methods directly because Octave doesn't support it
    meths = klass.MethodList;
    method_names = cell (size (meths));
    for i = 1:numel (meths)
      method_names{i} = meths{i}.Name;
    endfor
    cache(class_name) = method_names;  
  endif
  out = ismember (method_name, method_names);
endfunction

function out = ifthen (condition, true_value, false_value)
  if condition
    out = true_value;
  else
    out = false_value;
  endif
endfunction

function out = isintval (x)
  ## True if x is an integer value, even if held in a double
  out = rem (x, 1) == 0;
endfunction


%!assert (jsonencode (42), "42")
%!assert (jsonencode ("foo"), '"foo"')
%!assert (jsonencode ([1 2 3]), '[1, 2, 3]')
%!assert (jsonencode (NaN), 'null')
%!assert (jsonencode ([1 2 NaN]), '[1, 2, null]')
%!assert (jsonencode ({}), "[]")
