function obj=add_lines_executed_count(obj)
% increase line executed counter based on the state of mocov_line_covered
%
% obj=add_lines_executed_count(obj, lines)
%
% Inputs:
%   obj                 MOcovMFileCollection instance
%
% Output:
%   obj                 MOcovMFileCollection instance with the counts
%                       increased for all m-files recorded by
%                       mocov_line_covered
%
% See also: mocov_line_covered

    monitor=obj.monitor;

    if strcmp(obj.method,'profile')
        % Get data from Matlab's profiler
        abs_root_dir=mocov_get_absolute_path(obj.root_dir);
        set_mocov_line_covered_from_profile(abs_root_dir);
    end

    s=mocov_line_covered();

    filenames=s.keys;
    line_count=s.line_count;

    n=numel(filenames);
    msg=sprintf('%d files show coverage', n);
    notify(monitor,msg)

    for k=1:n
        fn=filenames{k};
        if isempty(fn) || all(line_count{k}==0)
            % no lines covered for this file
            continue;
        end
        [mfile,idx]=get_mfile(obj, fn);
        mfile=add_lines_executed_count(mfile, line_count{k});
        obj=set_mfile(obj, mfile, idx);
    end

function set_mocov_line_covered_from_profile(abs_root_dir)
    required_prefix=[abs_root_dir filesep()];
    has_prefix=@(fn)strncmp(required_prefix,fn,numel(required_prefix));

    pinfo=profile('info');
    function_table=pinfo.FunctionTable;

    filenames={function_table.FileName};
    n=numel(filenames);

    for k=1:n
        filename=filenames{k};

        if ~has_prefix(filename)
            continue;
        end

        rel_filename=mocov_get_relative_path(abs_root_dir,filename);

        executed=function_table(k).ExecutedLines;
        n_lines=size(executed,1);
        for j=1:n_lines
            line=executed(j,1);
            count=executed(j,2);
            mocov_line_covered(k,rel_filename,line,count);
        end
    end
