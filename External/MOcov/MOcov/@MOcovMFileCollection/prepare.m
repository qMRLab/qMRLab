function obj=prepare(obj)
% prepare for collecting coverage information
%
% obj=prepare(obj)
%
% Input:
%   obj                 MOcovMFileCollection instance
%
% Output:
%   obj                 MOcovMFileCollection instance with, if
%                       method=='file', the original path restored as well
%                       as mfiles rewritten to collect coverage
%                       information.

    monitor=obj.monitor;

    fns=mocov_find_files(obj.root_dir,'*.m',monitor,obj.exclude_pat);
    n=numel(fns);

    mfiles=cell(n,1);
    for k=1:n
        fn=fns{k};
        mfiles{k}=MOcovMFile(fn);
    end

    obj.mfiles=mfiles;

    if ~ischar(obj.method)
        error('method must be char, found %s', class(obj.method));
    end

    switch obj.method
        case 'profile'
            profile on
            notify(monitor,'','Enabling profiler');

        case 'file'
            % store original path
            obj.orig_path=path();
            notify(monitor,sprintf('Preserving original path\n'));

            temp_dir=tempname();
            notify(monitor,sprintf('Rewriting m-files\n'));
            obj=rewrite_mfiles(obj,temp_dir);

            addpath(genpath(temp_dir));
            notify(monitor,'',sprintf('Path is: %s\n', path()));

        otherwise
            error('illegal method %s', obj.method);
    end

    notify(monitor,sprintf('Coverage preparation complete\n'));