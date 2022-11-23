## Copyright (C) 2010-2018 John W. Eaton
## Copyright (C) 2019 Andrew Janke
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

function nfailed = __test_pkgs__ (pkg_names, options)
  %__TEST_PKGS__ Run tests for packages
  %
  % nfailed = __test_pkgs__ (pkg_names)
  % nfailed = __test_pkgs__ (pkg_names, options)
  %
  % pkg_names (cellstr) is a list of packages to test. If pkg_names is empty
  % or omitted, then all installed packages are tested.
  %
  % options (struct, cellstr) is a set of name/value pairs of options.
  % Valid options:
  %   all_together - (boolean, false*) If true, test packages while they are
  %                  all loaded together in addition to the individual package
  %                  tests.
  %   n_iters - (double, 1*) How many times to run each package test. This is
  %                  used for exposing intermittent failures.
  %   rand_seed - (double, 42.0*) Seed to reset rand() generator to for each
  %                  test.
  %
  % Returns the total number of test failures.
  %
  % Examples:
  %
  % % Test a single package
  % __test_pkgs__ ('control')
  %
  % % Test all installed packages
  % __test_pkgs__
  %
  % % Test all packages, including loading all together to check compatibility
  % __test_pkgs__ ([], {'all_together', true})
  %
  % % Torture test
  % __test_pkgs__ ([], {'all_together', true, 'n_iters', 4})

  if nargin < 1;  pkg_names = {};  endif
  if nargin < 2;  options = {};    endif

  default_opts = struct (...
    "all_together", false, ...
    "n_iters",      1, ...
    "rand_seed",    42.0);
  opts = parse_options (options, default_opts);

  if (isempty (pkg_names))
    pkg_names = list_installed_packages ();
  endif
  pkg_names = cellstr (pkg_names);

  nfailed = 0;

  pkgs_with_failures = {};

  fprintf ("Running package tests\n");
  fprintf ("Random seed is: %0.16f\n", opts.rand_seed);

  ## Test packages individually
  fprintf ("Testing packages individually...\n");
  for i = 1:numel (pkg_names)
    pkg_name = pkg_names{i};
    pkg_info = pkg ("list", pkg_name);
    pkg_info = pkg_info{1};
    fprintf ("\nTesting package %s %s\n", pkg_name, pkg_info.version);
    pkg_dir = pkg_info.dir;
    for i_iter = 1:opts.n_iters
      pkg ("load", pkg_name);
      rand ("seed", opts.rand_seed);
      nf = my_runtests (pkg_dir);
      if (nf > 0)
        pkgs_with_failures{end+1} = pkg_name;
      endif
      nfailed += nf;
      pkg ("unload", pkg_name);
    endfor
  endfor

  ## Test packages when they're all loaded together
  if (opts.all_together)
    fprintf ("\n\n\nLoading all packages together...\n");
    pkg ("load", pkg_names{:});
    for i = 1:numel (pkg_names)
      pkg_name = pkg_names{i};
      pkg_info = pkg ("list", pkg_name);
      pkg_info = pkg_info{1};
      fprintf ("\nTesting package %s %s\n", pkg_name, pkg_info.version);
      pkg_dir = pkg_info.dir;
      for i_iter = 1:opts.n_iters
        rand ("seed", opts.rand_seed);
        nf = my_runtests (pkg_dir);
        if (nf > 0)
          pkgs_with_failures{end+1} = pkg_name;
        endif
        nfailed += nf;
      endfor
    endfor
    pkg ("unload", pkg_names{:});
  endif

  fprintf ("\n");
  if (nfailed > 0)
    pkgs_with_failures = unique (pkgs_with_failures);
    fprintf ("TESTS FAILED!\n");
    fprintf ("%d failures in tests for packages: %s\n", ...
      nfailed, strjoin (pkgs_with_failures, " "));
  else
    fprintf ("All tests passed.\n");
  endif
  fprintf ("\n");

  if (nargout == 0)
    clear nfailed
  endif
endfunction

function out = parse_options (options, defaults)
  opts = defaults;
  if iscell (options)
    s = struct;
    for i = 1:2:numel (options)
      s.(options{i}) = options{i+1};
    endfor
    options = s;
  endif
  if (! isstruct (options))
    error ("options must be a struct or name/val cell vector");
  endif
  opt_fields = fieldnames (options);
  for i = 1:numel (opt_fields)
    opts.(opt_fields{i}) = options.(opt_fields{i});
  endfor
  out = opts;
endfunction

function out = list_installed_packages
  p = pkg ('list');
  if (isempty (p))
    out = {};
    return;
  endif
  out = cellfun (@(x) { x.name }, p);
end

## -*- texinfo -*-
## @deftypefn  {} {} runtests ()
## @deftypefnx {} {} runtests (@var{directory})
## Execute built-in tests for all m-files in the specified @var{directory}.
##
## Test blocks in any C++ source files (@file{*.cc}) will also be executed
## for use with dynamically linked oct-file functions.
##
## If no directory is specified, operate on all directories in Octave's search
## path for functions.
## @seealso{rundemos, test, path}
## @end deftypefn

## Author: jwe

function nfailed = my_runtests (directory)

  if (nargin == 0)
    dirs = ostrsplit (path (), pathsep ());
    do_class_dirs = true;
  elseif (nargin == 1)
    dirs = {canonicalize_file_name(directory)};
    if (isempty (dirs{1}) || ! isdir (dirs{1}))
      ## Search for directory name in path
      if (directory(end) == '/' || directory(end) == '\')
        directory(end) = [];
      endif
      fullname = dir_in_loadpath (directory);
      if (isempty (fullname))
        error ("runtests: DIRECTORY argument must be a valid pathname");
      endif
      dirs = {fullname};
    endif
    do_class_dirs = false;
  else
    print_usage ();
  endif

  nfailed = 0;
  for i = 1:numel (dirs)
    d = dirs{i};
    nfailed += run_all_tests (d, do_class_dirs);
  endfor

endfunction

function nfailed_total = run_all_tests (directory, do_class_dirs)

  nfailed_total = 0;
  flist = readdir (directory);
  dirs = {};
  no_tests = {};
  printf ("Processing files in %s:\n\n", directory);
  fflush (stdout);
  for i = 1:numel (flist)
    f = flist{i};
    if ((length (f) > 2 && strcmpi (f((end-1):end), ".m"))
        || (length (f) > 3 && strcmpi (f((end-2):end), ".cc")))
      ff = fullfile (directory, f);
      if (has_tests (ff))
        print_test_file_name (f);
        [p, n, xf, xb, sk, rtsk, rgrs] = test (ff, "quiet");
        nfailed = n - p - xf - xb - rgrs;
        nfailed_total += nfailed;
        print_pass_fail (p, n, xf, xb, sk, rtsk, rgrs);
        fflush (stdout);
      elseif (has_functions (ff))
        no_tests(end+1) = f;
      endif
    elseif (f(1) == "@")
      f = fullfile (directory, f);
      if (isdir (f))
        dirs(end+1) = f;
      endif
    endif
  endfor
  if (! isempty (no_tests))
    printf ("\nThe following files in %s have no tests:\n\n", directory);
    printf ("%s", list_in_columns (no_tests));
  endif

  ## Recurse into class directories since they are implied in the path
  if (do_class_dirs)
    for i = 1:numel (dirs)
      d = dirs{i};
      nfailed_total += run_all_tests (d, false);
    endfor
  endif

endfunction


function retval = has_functions (f)

  n = length (f);
  if (n > 3 && strcmpi (f((end-2):end), ".cc"))
    fid = fopen (f);
    if (fid < 0)
      error ("runtests: fopen failed: %s", f);
    endif
    str = fread (fid, "*char")';
    fclose (fid);
    retval = ! isempty (regexp (str,'^(?:DEFUN|DEFUN_DLD|DEFUNX)\>',
                                    'lineanchors', 'once'));
  elseif (n > 2 && strcmpi (f((end-1):end), ".m"))
    retval = true;
  else
    retval = false;
  endif

endfunction

function retval = has_tests (f)

  fid = fopen (f);
  if (fid < 0)
    error ("runtests: fopen failed: %s", f);
  endif

  str = fread (fid, "*char").';
  fclose (fid);
  retval = ! isempty (regexp (str,
                              '^%!(assert|error|fail|test|xtest|warning)',
                              'lineanchors', 'once'));

endfunction

function print_pass_fail (p, n, xf, xb, sk, rtsk, rgrs)

  if ((n + sk + rtsk + rgrs) > 0)
    printf (" PASS   %4d/%-4d", p, n);
    nfail = n - p - xf - xb - rgrs;
    if (nfail > 0)
      printf ("\n%71s %3d", "FAIL ", nfail);
    endif
    if (rgrs > 0)
      printf ("\n%71s %3d", "REGRESSION", rgrs);
    endif
    if (xb > 0)
      printf ("\n%71s %3d", "(reported bug) XFAIL", xb);
    endif
    if (xf > 0)
      printf ("\n%71s %3d", "(expected failure) XFAIL", xf);
    endif
    if (sk > 0)
      printf ("\n%71s %3d", "(missing feature) SKIP", sk);
    endif
    if (rtsk > 0)
      printf ("\n%71s %3d", "(run-time condition) SKIP", rtsk);
    endif
  endif
  puts ("\n");

endfunction

function print_test_file_name (nm)
  filler = repmat (".", 1, 60-length (nm));
  printf ("  %s %s", nm, filler);
endfunction

