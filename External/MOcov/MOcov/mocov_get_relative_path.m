function rel_fn=mocov_get_relative_path(root_dir, fn)
% return a path relative to another path
%
% rel_fn=mocov_get_relative_path(root_fn, fn)
%
% Input:
%   root_dir        root directory
%   fn              filename
%
% Output:
%   rel_fn          path of fn relative to root_fn, so that
%                   fullfile(root_fn,rel_fn)==fn
%

    abs_root_dir=mocov_get_absolute_path(root_dir);
    abs_fn=mocov_get_absolute_path(fn);

    n=numel(abs_root_dir);
    if ~strncmp(abs_root_dir,abs_fn,n)
        error('Absolute filename ''%s'' must start with ''%s''',...
                abs_fn, abs_root_dir);
    end

    if numel(abs_fn)==n
        rel_fn='';
        return;
    end

    if abs_fn(n+1)~=filesep()
        error('Expected path separator at position %d in ''%s''',...
                    n+1, abs_fn);
    end

    rel_fn=abs_fn((n+2):end);
