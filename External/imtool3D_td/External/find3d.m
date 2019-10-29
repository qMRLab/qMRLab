function [X,Y,Z]=find3d(input,varargin)
dimY=size(input,2);
[X,Y] = find(input,varargin{:});
Z = floor((Y-1)/dimY);
Y = Y - dimY*Z;
Z = Z + 1;