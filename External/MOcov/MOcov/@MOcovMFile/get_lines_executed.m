function msk=get_lines_executed(obj)
% get a mask indicating which lines have been executed
%
% msk=get_lines_executed(obj)
%
% Input:
%   obj                 MOcovMFile instance
%
% Output:
%   msk                 Nx1 logical mask, with msk(k)==true indicating
%                       that the k-th line has been executed at least once

    msk=get_lines_executed_count(obj)>0;