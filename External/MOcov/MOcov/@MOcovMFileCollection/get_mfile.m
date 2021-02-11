function [mfile,idx]=get_mfile(obj, fn)
% get mfile either by name or by index
%
% [mfile,idx]=get_mfile(obj, fn)
%
% Inputs:
%   obj                 @MOcovMFileCollection instance
%   fn                  filename or integer
%
% Outputs:
%   mfile               @MOcovMFile that either has name fn (if fn is a
%                       string) or is the fn-th file (if fn is numeric)
%   idx                 index of mfile within obj
%

    if isnumeric(fn)
        lookup_func=@get_mfile_numeric;
    else
        lookup_func=@get_mfile_by_name;
    end

    [mfile,idx]=lookup_func(obj,fn);

function [mfile,idx]=get_mfile_numeric(obj,idx)
    mfile=obj.mfiles{idx};

function [mfile,idx]=get_mfile_by_name(obj,fn)
    root_dir=obj.root_dir;
    abs_fn=mocov_get_absolute_path(fullfile(root_dir,fn));

    mfiles=obj.mfiles;
    n=numel(mfiles);
    for k=1:n
        mfile=mfiles{k};
        mfile_fn=get_filename(mfile);
        if strcmp(mfile_fn, abs_fn)
            [mfile,idx]=get_mfile_numeric(obj,k);
            return;
        end
    end

    error('Not found: %s', fn);
