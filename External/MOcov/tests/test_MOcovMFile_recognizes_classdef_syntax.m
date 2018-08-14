function test_suite = test_MOcovMFile_recognizes_classdef_syntax
    initTestSuite;
end

function assertStringContains(text, subtext)
    assert(~isempty(strfind(text, subtext)), ...
        'String ''%s'' should contain ''%s'', but it doesn''t.', ...
                        text, subtext);
end

function filepath = create_tempfile(filename, contents)
    % Creates a temporary file with the specified content.

    filepath = fullfile(tempdir, filename);
    fid = fopen(filepath, 'w');
    fprintf(fid, contents);
    fclose(fid);
end

function filepath = create_classdef(classname)
    if nargin < 1
        % Use a random name to ensure uniqueness
        classname = char(64 + ceil(26*rand(1, 20)));
    end

    filepath = create_tempfile([classname, '.m'], [ ...
        'classdef ', classname, ' < handle\n', ...
        '  properties\n', ...
        '    aProp;\n', ...
        '  end\n', ...
        '  properties (SetAccess = private, Dependent)\n', ...
        '    anotherProp;\n', ...
        '  end\n', ...
        '  methods\n', ...
        '    function self =  ', classname, ' \n', ...
        '      abs(1);\n', ...
        '    end\n', ...
        '  end\n', ...
        '  methods (Access = public)\n', ...
        '    function x = aMethod(self)\n', ...
        '      abs(2);\n', ...
        '    end\n', ...
        '  end\n', ...
        'end\n' ...
    ]);
end

function test_classdef_line_not_executable
    % Test subject: `MOcovMFile` constructor

    tempfile = create_classdef;
    teardown = onCleanup(@() delete(tempfile));

    mfile = MOcovMFile(tempfile);
    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);

    assertStringContains(lines{1}, 'classdef');
    assert(~executable_lines(1), ...
        '`classdef` line is wrongly classified as executable');
end

function test_methods_opening_section_not_executable
    % Test subject: `MOcovMFile` constructor

    tempfile = create_classdef;
    teardown = onCleanup(@() delete(tempfile));

    mfile = MOcovMFile(tempfile);
    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);
    method_opening = [8, 13];

    for n = method_opening
        assertStringContains(lines{n}, 'methods');
        assert(~executable_lines(n), ...
            '`%s` line is wrongly classified as executable', lines{n});
    end
end

function test_method_body_executable
    % Test subject: `MOcovMFile` constructor

    tempfile = create_classdef;
    teardown = onCleanup(@() delete(tempfile));

    mfile = MOcovMFile(tempfile);
    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);
    method_lines = [10, 15];

    for n = method_lines
        assertStringContains(lines{n}, 'abs(');
        assert(executable_lines(n), ...
            '`%s` line is wrongly classified as non-executable', lines{n});
    end
end

function test_properties_line_not_executable
    % Test subject: `MOcovMFile` constructor

    tempfile = create_classdef;
    teardown = onCleanup(@() delete(tempfile));

    mfile = MOcovMFile(tempfile);
    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);
    properties_opening = [2, 5];
    properties_body = [3, 6];

    for n = properties_opening
        assertStringContains(lines{n}, 'properties');
        assert(~executable_lines(n), ...
            '`%s` line is wrongly classified as executable', lines{n});
    end

    for n = properties_body;
        assertStringContains(lines{n}, 'Prop;');
        assert(~executable_lines(n), ...
            '`%s` line is wrongly classified as executable', lines{n});
    end
end

function test_generate_valid_file
    % Test subject: `write_lines_with_prefix` method

    original_path = path;
    path_cleanup = onCleanup(@() path(original_path));

    % Given:

    % `AClass.m` file with a classdef declaration
    classname = ['AClass', char(64 + ceil(26*rand(1, 20)))];
    tempfile = create_classdef(classname);
    teardown = onCleanup(@() delete(tempfile));
    % a valid decorator (which does nothing)
    decorator = @(line_number) ...
        sprintf('abs(3);');

    % When: the decorated file is generated
    mfile = MOcovMFile(tempfile);
    write_lines_with_prefix(mfile, tempfile, decorator);
        % ^ Here we just overwrite the original file, because we don't use it.
        %   In the real word, the new file should be saved to a
        %   different folder.

    % Then: the decorated file should have a valid syntax
    % Since Octave do not have a linter, run the code to check the syntax.
    addpath(tempdir);
    try
        constructor = str2func(classname);
        aObject = constructor();
        aObject.aMethod();
    catch
        assert(false, ['Problems when running the decoated file: ', ...
                       '%s - please check for syntax errors.'], tempfile);
    end
end

