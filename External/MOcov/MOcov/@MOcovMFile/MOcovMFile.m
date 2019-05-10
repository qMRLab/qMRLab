function obj=MOcovMFile(fn)
% instantiate MOcov m-file representation of line coverage
%
% obj=MOcovMFile(fn)
%
% Input:
%   fn                  Filename of .m file
%
% Output:
%   obj                 MOcovMFile instance that contains, internally,
%                       the filename, each line of the m-file, which lines
%                       are executable, and an array counting how often
%                       each line has been executed.

    props=get_mfile_props(fn);
    obj=class(props,'MOcovMFile');

function props=get_mfile_props(fn)
    % get properties of a matlab file. The output has
    %   .filename: filename of mfile
    %   .executable:        Nx1 boolean array for N lines,
    %                       indicating which lines can be executed
    %   .executed_count:    Nx1 false array
    %   .lines              Nx1 cellstr with lines of mfile

    % read the matlab file
    fid=fopen(fn);
    cleaner=onCleanup(@()fclose(fid));
    s=fread(fid,inf,'char=>char')';

    % split by newline character
    lines=regexp(s,sprintf('\n'),'split');


    % state variables
    in_line_continuation = false;  % whether the previous line contained a
                                   % line continuation, i.e. ended with '...'

    inside_class = false;  % the file contains a `classdef` statement

    inside_properties = false; % a `properties` section was opened
                               % but not closed.

    % see which lines are executable
    n=numel(lines);
    executable=false(n,1);
    for k=1:n
        line=lines{k};

        line_without_quotes=regexprep(line,'''.*''','');

        comment_start=find(line_without_quotes=='%',1);
        if isempty(comment_start)
            line_code=line_without_quotes;
        else
            line_code=line_without_quotes(1:(comment_start-1));
        end


        line_code_trimmed=regexprep(line_code,'\s','');
        if isempty(line_code_trimmed)
            continue;
        end

        % Check for statements that ~changes/depends on~ the 'parser' state
        classdef_statement = line_is_class_def(line_code_trimmed);
        inside_class = inside_class || classdef_statement;

        properties_section = line_opens_properties_section(...
            line_code_trimmed, inside_class);
        % When a properties section is opened set the inside_properties flag
        inside_properties = inside_properties || properties_section;
        % When inside_properties is set and an 'end' appears, the section
        % is closed.
        % This can be considered a hack, since assumes no code that includes
        % an `end` is allowed inside properties.
        inside_properties = inside_properties && ...
            ~line_ends_with_end_statement(line_code_trimmed);

        % classify line
        executable(k)=~(...
            in_line_continuation || ...
            line_is_function_def(line_code_trimmed) || ...
            classdef_statement || ...
            line_opens_methods_section(line_code_trimmed, inside_class) || ...
            inside_properties || ...  % Arbitrary code cannot run inside
            ...                       % properties section, just a subset
            line_is_case_statement(line_code) || ...
            line_is_elseif_statement(line_code) || ...
            line_is_else_statement(line_code) || ...
            line_is_sole_end_statement(line_code_trimmed));

        in_line_continuation=numel(line_code_trimmed)>=3 && ...
                               strcmp(line_code_trimmed(end+(-2:0)),'...');
    end

    % put results in struct
    props=struct();
    props.filename=mocov_get_absolute_path(fn);
    props.executable=executable;
    props.executed_count=zeros(size(props.executable));
    props.lines=lines;


function tf=line_is_function_def(line)
    % returns true if the string in line indicates a function definition
    newline=sprintf('\n');
    pat=[newline '\s*function([\[\]\w ,~]*=)?[ ]*'...
                 '(?<name>[a-zA-Z]\w*)(\([^\)]*\))?'];

    tf=~isempty(regexp([newline line],pat,'once'));

function tf=line_is_class_def(line)
    % returns true if the line opens a class definition
    tf=~isempty(regexp(line,'^\s*classdef\W*','once'));

function tf=line_opens_methods_section(line, inside_class)
    % returns true if the line opens a method section inside class definition
    tf=inside_class && ...
       ~isempty(regexp(line,'^\s*methods\s*(\([^\(\)]*\))?\s*$','once'));

function tf=line_opens_properties_section(line, inside_class)
    % returns true if the line opens a properties section inside class definition
    tf=inside_class && ...
       ~isempty(regexp(line,'^\s*properties\s*(\([^\(\)]*\))?\s*$','once'));

function tf=line_is_sole_end_statement(line)
    % returns true if the string in line is just an end statement
    tf=isempty(regexprep(line,'([\s,;]|^)?end([\s,;]|$)?',''));

function tf=line_is_case_statement(line)
    tf=~isempty(regexp(line,'^\s*case\W*','once'));

function tf=line_is_elseif_statement(line)
    tf=~isempty(regexp(line,'^\s*elseif\W*','once'));

function tf=line_is_else_statement(line)
    tf=~isempty(regexp(line,'^\s*else\W*','once'));

function tf=line_ends_with_end_statement(line)
    % returns true if the line has a finishing 'end'
    tf=~isempty(regexp(line,'(^|\W)end\s*[,;]?\s*$','once'));
