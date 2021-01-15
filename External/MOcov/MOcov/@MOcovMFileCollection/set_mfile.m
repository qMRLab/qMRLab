function obj=set_mfile(obj, mfile, idx)
% set MOCovMFile
%
% obj=set_mfile(obj, mfile, idx)
%
% Inputs:
%   obj                     MOcovMFileCollection instance
%   mfile                   MOcovMFile instance
%   idx                     position
%
% Output:
%   obj                     MOcovMFileCollection instance with mfile stored
%                           in the idx-th position.

    obj.mfiles{idx}=mfile;