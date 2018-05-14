function write_lines_with_prefix(obj, fn, decorator)
% write lines in mfile with prefix
%
% write_lines_with_prefix(obj, fn, decorator)
%
% Inputs:
%   obj                 MOcovMFile instance
%   fn                  output filename
%   decorator           function handle which takes a single argument with
%                       a line number, and returns a prefix string that
%                       forms an expression that can be evaluated. When
%                       called, each executable line is prefixed with its
%                       corresponding prefix expression and the results are
%                       written to the output file fn.
%
% Notes:
%   - the typical value for decorator is a function that returns
%       mocov_line_covered(fn,k)
%     with k the input line number. This provides functionality to keep
%     track of which lines are covered.

    orig_lines=get_lines(obj);
    n=numel(orig_lines);

    executable=get_lines_executable(obj);

    new_lines=cell(1,n);
    for k=1:n
        line=orig_lines{k};

        if executable(k)
            prefix=decorator(k);
        else
            prefix='';
        end

        new_lines{k}=sprintf('%s%s\n',prefix,line);
    end

    pth=fileparts(fn);
    mkdir_recursively(pth);

    fid=fopen(fn,'w');
    cleaner=onCleanup(@()fclose(fid));
    fprintf(fid,'%s',new_lines{:});


function mkdir_recursively(pth)
    if ~isempty(pth) && ~isdir(pth)
        parent=fileparts(pth);
        mkdir_recursively(parent);
        mkdir(pth);
    end