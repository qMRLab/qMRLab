function obj=set_lines_executed(obj)
    monitor=obj.monitor;

    if strcmp(obj.method,'profile')
        abs_root_dir=mocov_get_absolute_path(obj.root_dir);
        set_mocov_line_covered_from_profile(abs_root_dir);
    end

    s=mocov_line_covered();

    filenames=s.keys;
    lines=s.lines;

    n=numel(filenames);
    msg=sprintf('%d files show coverage', n);
    notify(monitor,msg)


    for k=1:n
        [mfile,idx]=get_mfile(obj, filenames{k});
        mfile=set_lines_executed(mfile, lines{k});
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

        lines=function_table(k).ExecutedLines(:,1)';
        for line=lines
            mocov_line_covered(rel_filename,line);
        end
    end
