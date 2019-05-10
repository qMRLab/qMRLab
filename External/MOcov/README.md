# MOcov [![Build Status](https://travis-ci.org/MOcov/MOcov.svg?branch=master)](https://travis-ci.org/MOcov/MOcov)

MOcov is a coverage report generator for Matlab and GNU Octave.


### Features

- Runs on both the [Matlab] and [GNU Octave] platforms.
- Can be used directly with continuous integration services, such as [coveralls.io] and [Shippable].
- Integrates with [MOxUnit], a unit test framework for Matlab and GNU Octave.
- Supports the Matlab profiler.
- Writes coverage reports in HTML, JSON and XML formats.
- Distributed under the MIT license, a permissive free software license.


### Installation

- Using the shell (requires a Unix-like operating system such as GNU/Linux or Apple OSX):

    ```bash
    git clone https://github.com/MOcov/MOcov.git
    cd MOcov
    make install
    ```
    This will add the MOcov directory to the Matlab and/or GNU Octave search path. If both Matlab and GNU Octave are available on your machine, it will install MOcov for both.

- Manual installation:

    + Download the zip archive from the [MOcov] website.
    + Start Matlab or GNU Octave.
    + On the Matlab or GNU Octave prompt, `cd` to the `MOcov` root directory, then run:
    
        ```matlab
        cd MOcov            % cd to MOcov subdirectory
        addpath(pwd)        % add the current directory to the Matlab/GNU Octave path
        savepath            % save the path
        ```


### Determining coverage

Coverage can be determined for evaluating a single expression or evaluation of a single function handle; for typical use cases this invokes running a test suite. 

There are two methods to generate coverage while evaluating such an expression or function handle:

1. the 'file' method (default)

    - Coverage information is stored internally by the function `mocov_line_covered`, which keeps this information through the use of persistent variables. Initially the coverage information is reset to being empty.
    - This method considers all files in a directory (and its subdirectories).
    - A temporary directory is created where modified versions of each file is stored.
    - Prior to evaluting the expression or function handle, for each file, MOcov determines which of its lines can be executed. Each line that can be executed is prefixed by a call to `mocov_line_covered`, which cause it to update internal state to record the filename and line number that was executed, and the result stored in the temporary directory.
    - The search path is updated to include the new temporary directory.
    
    After evaluating the expression or function handle, the temporary directory is deleted and the search path restored. Line coverage information is then extracted from the internal state of `mocov_line_covered`.
    
    This method runs on both GNU Octave and Matlab, but is typically slow.

2. the 'profile' method
    - It uses the Matlab profiler. 
    - This method runs on Matlab only (not on GNU Octave), but is generally faster.


### Use cases

Typical use cases for MOcov are:

-   Locally run code with coverage for code in a unit test framework on GNU Octave or Matlab. Use

    ```matlab    
        mocov('-cover','path/with/code',...
                '-expression','run_test_command',...
                '-cover_json_file','coverage.json',...
                '-cover_xml_file','coverage.xml',...
                '-cover_html_dir','coverage_html',
                '-method','file');
    ```

    to generate coverage reports for all files in the `'path/with/code'` directory when `running eval('run_test_command')`. Results are stored in JSON, XML and HTML formats.

-   As a specific example of the use case above, when using the [MOxUnit] unit test platform such tests can be run as

    ```matlab
        success=moxunit_runtests('path/with/tests',...
                                    '-with_coverage',...
                                    '-cover','/path/with/code',...
                                    '-cover_xml_file','coverage.xml',...
                                    '-cover_html_dir','coverage_html');
    ```

    where `'path/with/tests'` contains unit tests. In this case, `moxunit_runtests` will call the `mocov` function to generate coverage reports.

-   On the Matlab platform, results from `profile('info')` can be stored in JSON, XML or HTML formats directly. In the following:

    ```matlab
        % enable profiler
        profile on;

        % run code for which coverage is to be determined
        <your code here>

        % write coverage based on profile('info')
        mocov('-cover','path/with/code',...
                '-profile_info',...
                '-cover_json_file','coverage.json',...
                '-cover_xml_file','coverage.xml',...
                '-cover_html_dir','coverage_html');
    ```

    coverage results are stored in JSON, XML and HTML formats.

-   Use with continuous integration service, such as [Shippable] or [travis-ci] combined with [coveralls.io]. See the   [travis.yml configuration file] in the [MOxUnit] project for an example.


### Use with travis-ci and Shippable
MOcov can be used with the [Travis-ci] and [Shippable] services for continuous integration testing. This is achieved by setting up a `travis.yml` file. Due to recursiveness issues, MOcov cannot use these services to generate coverage reports for itself; for an example in the related [MOxUnit] project, see the [travis.yml configuration file] file.


### Compatibility notes
- Because GNU Octave 3.8 and 4.0 do not support `classdef` syntax, 'old-style' object-oriented syntax is used for the class definitions. 


### Limitations
- The 'file' method uses a very simple parser, which may not work as expected in all cases.
- Currently there is only support to generate coverage reports for files in a single directory (and its subdirectory).


### Contact
Nikolaas N. Oosterhof, nikolaas dot oosterhof at unitn dot it


### Contributions
- Thanks to Scott Lowe and Anderson Bravalheri for their contributions.


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
[MOxUnit]: https://github.com/MOxUnit/MOxUnit
[MOcov]: https://github.com/MOcov/MOcov
[MOxUnit .travis.yml]: https://github.com/MOxUnit/MOxUnit/blob/master/.travis.yml
[Travis-ci]: https://travis-ci.org
[coveralls.io]: https://coveralls.io/
[travis.yml configuration file]: https://github.com/MOxUnit/MOxUnit/blob/master/.travis.yml
[Shippable]: https://shippable.com

