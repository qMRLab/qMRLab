function count=get_lines_executed_count(obj)
% get a mask indicating which lines have been executed
%
% count=get_lines_executed_count(obj)
%
% Input:
%   obj                 MOcovMFile instance
%
% Output:
%   count               Nx1 numeric vector, with count(k)=c indicating
%                       that the k-th line has been executed k times. Lines
%                       that are marked as non-executable have a value of
%                       zero.

    count=obj.executed_count;
    count(~get_lines_executable(obj))=0;