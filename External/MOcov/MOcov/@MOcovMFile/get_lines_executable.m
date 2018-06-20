function msk=get_lines_executable(obj)
% get a mask indicating which lines are executable
%
% msk=get_lines_executable(obj)
%
% Input:
%   obj                 MOcovMFile instance
%
% Output:
%   msk                 Nx1 logical mask, with msk(k)==true indicating
%                       that the k-th line can be exectued

    msk=obj.executable;