# MOxUnit [![Build Status](https://travis-ci.org/nno/MOxUnit.svg?branch=master)](https://travis-ci.org/MOxUnit/MOxUnit) [![Coverage Status](https://coveralls.io/repos/github/MOxUnit/MOxUnit/badge.svg?branch=master)](https://coveralls.io/github/MOxUnit/MOxUnit?branch=master)

MOxUnit is a lightweight unit test framework for Matlab and GNU Octave.

### Features

- Runs on both the [Matlab] and [GNU Octave] platforms.
- Uses object-oriented TestCase, TestSuite and TestResult classes, allowing for user-defined extensions.
- Can be used directly with continuous integration services, such as [Travis-ci] and [Shippable].
- Supports JUnit-like XML output for use with Shippable and other test results visualization approaches.
- Supports the generation of code coverage reports using [MOCov]
- Provides compatibility with the (now unsupported) Steve Eddin's [Matlab xUnit test framework], and with recent Matlab.
- Distributed under the MIT license, a permissive free software license.


### Installation

- Using the shell (requires a Unix-like operating system such as GNU/Linux or Apple OSX):

    ```bash
    git clone https://github.com/MOxUnit/MOxUnit.git
    cd MOxUnit
    make install
    ```
    This will add the MOxUnit directory to the Matlab and/or GNU Octave searchpath. If both Matlab and GNU Octave are available on your machine, it will install MOxUnit for both.

- Manual installation:

    + Download the [[MOxUnit zip archive] from the [MOxUnit] website, and extract it. This should
      result in a directory called ``MOxUnit-master``.
    + Start Matlab or GNU Octave.
    + On the Matlab or GNU Octave prompt, go to the directory that contains the new ``MOxUnit-master`` directory, then run:

        ```matlab
        % change to the MOxUnit subdirectory
        %
        % Note: if MOxUnit was retrieved using 'git', then the name of
        %       top-level directory is 'MOxUnit', not 'MOxUnit-master'
        cd MOxUnit-master/MoxUnit

        % add the current directory to the Matlab/GNU Octave path
        moxunit_set_path()

        % save the path
        savepath
        ```

### Running MOxUnit tests

- `cd` to the directory where the unit tests reside. For MOxUnit itself, the unit tests are in the directory `tests`.
- run the tests using `moxunit_runtests`. For example, running `moxunit_runtests` from MOxUnit's `tests` directory runs tests for MOxUnit itself, and should give the following output:

  ```
............................................................
.........................
--------------------------------------------------
OK (passed=85)

ans =

     1
  ```

- `moxunit_runtests`, by default, gives non-verbose output and runs all tests in the current directory. This can be changed using the following arguments:
  - `-verbose`: show verbose output.
  - `directory`: run unit tests in directory `directory`.
  - `file.m`: run unit tests in file `file.m`.
  - `-recursive`: add files from directories recursively.
  - `-logfile logfile.txt`: store the output in file `logfile.txt`.
  - `-junit_xml_file xmlfile`: store JUnit-like XML output in file `xmlfile`.

- To test MOxUnit itself from a terminal, run:

  ```
    make test
  ```

### Use with travis-ci and Shippable
MOxUnit uses the [Travis-ci] service for continuous integration testing. This is achieved by setting up a [.travis.yml configuration file](.travis.yml). This file is also used by [Shippable].
As a result, the test suite is run automatically on both [Travis-ci] and [Shippable] every time it is pushed to the github repository, or when a pull request is made. If a test fails, or if all tests pass after a test failed before, the developers are notified by email.

### Defining MOxUnit tests

To define unit tests, write a function with the following header:

```matlab
function test_suite=my_test_of_abs
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;
```

*Important*:
- it is crucial that the output of the main function is a variable named `test_suite`, and that the output of `localfunctions` is assigned to a variable named `test_functions`
- as of Matlab 2016b, Matlab scripts (such as `initTestSuite.m`) do not have access to subfunctions in a function if called from that function. Therefore it requires using localfunctions to obtain function handles to local functions. The "try-catch-end" statements are necessary for compatibility with older versions of GNU Octave, which do not provide the `localfunctions` function.

Then, define subfunctions whose name start with `test` or end with `test` (case-insensitive). These functions can use the following `assert*` functions:
- `assertTrue(a)`: assert that `a` is true.
- `assertFalse(a)`: assert that `a` is false.
- `assertEqual(a,b)`: assert that `a` and `b` are equal.
- `assertElementsAlmostEqual(a,b)`: assert that the floating point arrays `a` and `b` have the same size, and that corresponding elements are equal within some numeric tolerance.
- `assertVectorsAlmostEqual(a,b)`: assert that floating point vectors `a` and `b` have the same size, and are equal within some numeric tolerance based on their vector norm.
- `assertExceptionThrown(f,id)`: assert that calling `f()` throws an exception with identifier `id`. (To deal with cases where Matlab and GNU Octave throw errors with different identifiers, use `moxunit_util_platform_is_octave`. Or use `id='*'` to match any identifier).

As a special case, `moxunit_throw_test_skipped_exception('reason')` throws an exception that is caught when running the test; `moxunit_run_tests` will report that the test is skipped for reason `reason`.

For example, the following function defines three unit tests that tests some possible inputs from the builtin `abs` function:
```matlab
function test_suite=my_test_of_abs
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_abs_scalar
    assertTrue(abs(-1)==1)
    assertEqual(abs(-NaN),NaN);
    assertEqual(abs(-Inf),Inf);
    assertEqual(abs(0),0)
    assertElementsAlmostEqual(abs(-1e-13),0)

function test_abs_vector
    assertEqual(abs([-1 1 -3]),[1 1 3]);

function test_abs_exceptions
    % GNU Octave and Matlab use different error identifiers
    if moxunit_util_platform_is_octave()
        assertExceptionThrown(@()abs(struct),'');
    else
        assertExceptionThrown(@()abs(struct),...
                             'MATLAB:UndefinedFunction');
    end
```

Examples of unit tests are in MOxUnit's `tests` directory, which test some of MOxUnit's functions itself.

### Compatibility notes
- Because GNU Octave 3.8 does not support `classdef` syntax, 'old-style' object-oriented syntax is used for the class definitions. For similar reasons, MOxUnit uses the `lasterror` function, even though its use in Matlab is discouraged.
- Recent versions of Matlab (2016 and later) do not support tests defined just using "initTestSuite", that is without the use of `localfunctions` (see above). To ease the transition, consider using the Python script `tools/fix_mfile_test_init.py`, which can update existing .m files that do not use `localfunctions`.

  For example, the following command was used on a Unix-like shell to preview changes to MOxUnit's tests:

  ```
    find tests -iname 'test*.m' | xargs -L1 tools/fix_mfile_test_init.py
  ```

  and adding the `--apply` option applies these changes, meaning that found files are rewritten:

  ```
    find tests -iname 'test*.m' | xargs -L1 tools/fix_mfile_test_init.py --apply
  ```
- Recent versions of Matlab define a `matlab.unittest.Test` class for unit tests. An instance `t` can be used with MOxUnit using the `MOxUnitMatlabUnitWrapperTestCase(t)`, which is a `MOxUnitTestCase` instance. Tests that are defined through

    ```
    function tests=foo()
        tests=functiontests(localfunctions)

    function test_funcA(param)

    function test_funcA(param)
    ```

  can be run using MOxUnit as well (and included in an ``MOxUnitTestSuite`` instance using its with ``addFile``) instance, with the exception that currently setup and teardown functions are currently ignored.

### Acknowledgements
- The object-oriented class structure was inspired by the [Python unit test] framework.
- The `assert*` function signatures are aimed to be compatible with Steve Eddin's [Matlab xUnit test framework].


### Limitations
Currently MOxUnit does not support:
- Documentation tests. These would require `evalc`, which is not available in `GNU Octave` as of January 2014.
- Support for setup and teardown functions in `TestCase` classes.
- Subclasses of MOxUnit's classes (`MOxUnitTestCase`, `MOxUnitTestSuite`, `MOxUnitTestReport`) have to be defined using "old-style" object-oriented syntax.


### Contact
Nikolaas N. Oosterhof, n dot n dot oosterhof at googlemail dot com.


### Contributions
- Thanks to Scott Lowe, Thomas Feher, Joel LeBlanc and Anderson Bravalheri for contributions.


### Frequently Asked Questions (FAQ)
- *I would like to use unit tests with travis for a Matlab project. Can I use MOxUnit?*

  Yes, as long as your code is Octave compatible, as it seems not possible to run the proprietary Matlab software on travis ( (if you found a way to do this, please let us know and we will update this entry). Also bear in mind that many Matlab projects tend to use functionality not present in Octave (such as particular functions), whereasand writing code that is both Matlab- and Octave-compatible may require some additional efforts.

- *If I want to use travis for running tests, what should I put in `.travis.yml`?*

  MOxUnit tests itself on travis, and this is the travis file:

    https://github.com/MOxUnit/MOxUnit/blob/master/.travis.yml

  It uses the Makefile to run the tests. To avoid a Makefile and run tests directly through Octave, `.travis.yml` needs a line that calls Octave to run the tests. For example:

  ```
  octave --no-gui --eval "addpath('~/git/MOxUnit/MOxUnit');moxunit_set_path;moxunit_runtests('tests')"
  ```


### License

(The MIT License)

Copyright (c) 2015-2017 Nikolaas N. Oosterhof

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



[GNU Octave]: http://www.gnu.org/software/octave/
[Matlab]: http://www.mathworks.com/products/matlab/
[Matlab xUnit test framework]: http://it.mathworks.com/matlabcentral/fileexchange/22846-matlab-xunit-test-framework
[MOxUnit]: https://github.com/MOxUnit/MOxUnit
[MOxUnit zip archive]: https://github.com/MOxUnit/MOxUnit/archive/master.zip
[MOcov]: https://github.com/MOcov/MOcov
[Python unit test]: https://docs.python.org/2.6/library/unittest.html
[Travis-ci]: https://travis-ci.org
[Shippable]: https://app.shippable.com/





