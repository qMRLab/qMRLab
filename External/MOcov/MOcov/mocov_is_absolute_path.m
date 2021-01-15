function tf=mocov_is_absolute_path(fn)
% indicate whether a path is absolute
%
% tf=mocov_is_absolute_path(fn)
%
% Input:
%   fn          filename or path
%
% Output:
%   tf          true if fn is an absolute path, false otherwise
%

    n=numel(fn);
    if ispc()
        tf=n>=2 && fn(2)==':';
    else
        tf=n>=1 && (fn(1)=='/' || fn(1)=='~');
    end