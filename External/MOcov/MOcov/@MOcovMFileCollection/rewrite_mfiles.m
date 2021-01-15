function obj=rewrite_mfiles(obj, temp_dir)
% rewrite m-files for collecting coverage information
%
% obj=rewrite_mfiles(obj, temp_dir)
%
% Input:
%   temp_dir            Temporary directory in which rewritten m-files have
%                       to be stored
%   obj                 MOcovMFileCollection instance
%
% Output:
%   obj                 MOcovMFileCollection instance with the MOcovMFile
%                       instances rewritten to collect coverage
%                       information.
%

    obj.temp_dir=temp_dir;

    mfiles=obj.mfiles;
    if ~iscell(mfiles)
        error('No mfiles - did you call ''prepare''?');
    end

    root_dir=obj.root_dir;

    n=numel(mfiles);
    for k=1:n
        mfile=mfiles{k};

        fn=get_filename(mfile);

        rel_fn=mocov_get_relative_path(root_dir, fn);
        tmp_fn=fullfile(temp_dir, rel_fn);

        pat=sprintf('mocov_line_covered(%d,''%s'',%%d,1);',k,rel_fn);
        decorator=@(line_number) sprintf(pat,line_number);
        write_lines_with_prefix(mfile, tmp_fn, decorator);
        notify(obj.monitor,'.',sprintf('Rewrote %s', rel_fn));
    end

