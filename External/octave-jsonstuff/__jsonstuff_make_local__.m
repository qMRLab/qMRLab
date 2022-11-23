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
## @deftypefn {Function File} __jsonstuff_make_local__
##
## Build all the octfiles in JsonStuff.
##
## This is for use when you are building this JsonStuff from the source in the repo. It
## is not needed when you are using this JsonStuff after it is installed. You do not need
## to call it yourself if you install this JsonStuff using @command{pkg}.
##
## @end deftypefn

function __jsonstuff_make_local__
  ## OCTAVE_JSONSTUFF_MAKE_LOCAL Build the octfiles for this repo
  ##
  ## Call this function if you are working with a local copy of this repo instead
  ## of installing it as a package.
  d = dir;
  if (! ismember ([mfilename '.m'], {d.name}))
    [my_dir, me] = fileparts (mfilename ('fullpath'));
    error (['You are calling this function (%s) from the wrong directory.\n' ...
      '%s needs to be run from the directory it lives in.\n' ...
      'cd to %s and try again.'], ...
      mfilename, my_dir);
  endif
  ## TODO: Replace this hardcoded list with src/*.cc
  octfcns = {
    '__jsonstuff_jsondecode_oct__'
    };
  for i = 1:numel (octfcns)
    octfcn = octfcns{i};
    src_file = sprintf ('src/%s.cc', octfcn);
    mkoctfile (src_file, '-l jsoncpp');
    delete (sprintf ('%s.o', octfcn));
    movefile (sprintf ('%s.oct', octfcn), 'inst');
    printf (sprintf ('Built %s\n', octfcn));
  endfor
endfunction
