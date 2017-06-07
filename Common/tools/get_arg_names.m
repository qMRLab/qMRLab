function [inputNames, outputNames] = get_arg_names(filePath)

    %# Open the file:
    fid = fopen(filePath);

    %# Skip leading comments and empty lines:
    defLine = '';
    while all(isspace(defLine))
        defLine = strip_comments(fgets(fid));
    end

    %# Collect all lines if the definition is on multiple lines:
    index = strfind(defLine, '...');
    while ~isempty(index)
        defLine = [defLine(1:index-1) strip_comments(fgets(fid))];
        index = strfind(defLine, '...');
    end

    %# Close the file:
    fclose(fid);

    %# Create the regular expression to match:
    matchStr = '\s*function\s+';
    if any(defLine == '=')
        matchStr = strcat(matchStr, '\[?(?<outArgs>[\w, ]*)\]?\s*=\s*');
    end
    matchStr = strcat(matchStr, '\w+\s*\(?(?<inArgs>[\w, ]*)\)?');

    %# Parse the definition line (case insensitive):
    argStruct = regexpi(defLine, matchStr, 'names');

    %# Format the input argument names:
    if isfield(argStruct, 'inArgs') && ~isempty(argStruct.inArgs)
        inputNames = strtrim(textscan(argStruct.inArgs, '%s', ...
                                      'Delimiter', ','));
    else
        inputNames = {};
    end

    %# Format the output argument names:
    if isfield(argStruct, 'outArgs') && ~isempty(argStruct.outArgs)
        outputNames = strtrim(textscan(argStruct.outArgs, '%s', ...
                                       'Delimiter', ','));
    else
        outputNames = {};
    end

%# Nested functions:

    function str = strip_comments(str)
        if strcmp(strtrim(str), '%{')
            strip_comment_block;
            str = strip_comments(fgets(fid));
        else
            str = strtok([' ' str], '%');
        end
    end

    function strip_comment_block
        str = strtrim(fgets(fid));
        while ~strcmp(str, '%}')
            if strcmp(str, '%{')
                strip_comment_block;
            end
            str = strtrim(fgets(fid));
        end
    end

end