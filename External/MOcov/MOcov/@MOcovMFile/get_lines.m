function lines=get_lines(obj)
% get the lines of an m-file
%
% lines=get_lines(obj)
%
% Input:
%   obj                 MOcovMFile instance
%
% Output:
%   lines               Nx1 cell with strings, if the m-file has N lines

    lines=obj.lines;