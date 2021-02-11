function count=count_mfiles(obj)
% return the number of m-files
%
% count=count_mfiles(obj)
%
% Inputs:
%   obj                 MOcovMFileCollection instance
%
% Output:
%   count               number of MOcovMFile instances represented in the
%                       obj collection instance
%

    count=numel(obj.mfiles);