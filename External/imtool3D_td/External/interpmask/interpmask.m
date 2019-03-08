function BWout = interpmask( varargin )
%INTERPMASK Mask interpolation (tweening) via distance maps
%
%   BWq = INTERPMASK(X,BW,Xq) interpolates masks in the logical matrix BW
%   at query points Xq. The elements of X corresponds to the successive
%   masks along the last dimension of BW. The output BWq is a logical
%   matrix of equal size to BW except for the last dimension which is equal
%   to the number of query points in Xq.
%
%   BWq = INTERPMASK(...,'interpDim',D) specifies D as the dimension of BW
%   to interpolate along. By default, D is simply the last dimension of BW.
%
%   BWq = INTERPMASK(BW,Xq) assumes X = 1:N, where N is SIZE(BW,INTERPDIM).
%
%   Interpolation between masks is done via the distance matrix of each
%   mask in BW (calculated by BWDIST from the IP toolbox) using INTERP1.
%   Extra arguments ('linear', 'pchip', 'extrapval', etc) will be passed to
%   INTERP1 and can be used to control the interpolation method. To provide
%   an 'extrapval' to the output BWq mask, pass an 'extrapval' of 1 (TRUE)
%   or -1 (FALSE) to INTERPMASK as follows:
%
%   BWq = INTERPMASK(...,'pchip','extrapval',-1) % Extrap pixels set FALSE
%
%   For example, to interpolate smoothly from a small circle to a large
%   square to a large circle, consider the following:
%     % Make two circles and a rectangle
%     [x,y] = meshgrid(-51:51,-51:51);
%     circMat = sqrt(x.^2 + y.^2);
%     smallCirc = circMat<10;
%     largeCirc = circMat<30;
%     largeRect = false(size(x));
%     largeRect(2:100,2:100) = true;
%     % Stack them as masks 1, 2, and 3
%     BW = cat(3,smallCirc,largeRect,largeCirc);
%     % Interpolate smoothly between masks
%     BWout1 = interpmask(1:3, BW, linspace(1,3,200),'linear');
%     BWout2 = interpmask(1:3, BW, linspace(1,3,200),'pchip');
%     figure, subplot(1,2,1)
%     patch(isosurface(BWout1,0.5),'FaceColor','g','EdgeColor','none')
%     camlight, view(3), camlight, axis image
%     subplot(1,2,2)
%     patch(isosurface(BWout2,0.5),'FaceColor','g','EdgeColor','none')
%     camlight, view(3), camlight, axis image
%
%   See also INTERP1.

[X,BW,Xq,interpDim,interp1ArgInds] = parseInputs(varargin{:});

interpDimLen = size(BW,interpDim);
maxDim = ndims(BW);
% Build a distance map matrix, -ve away from mask, +ve inside mask
D = zeros(size(BW));
subs = repmat({':'},1,maxDim);
for i = 1:interpDimLen
    subs{interpDim} = i;
    BWi = BW(subs{:});
    D(subs{:}) = bwdist(~BWi) - bwdist(BWi);
end

% Ensure interpDim is the last dimension
if interpDim~=maxDim
    dimPerm = 1:maxDim;
    dimPerm = [dimPerm(dimPerm~=interpDim) interpDim];
    D = permute(D, dimPerm);
end

% Reshape to 2D matrix shape that interp1 handles
prevSize = size(D);
D = reshape(D,[],interpDimLen)';
prevSize(end) = length(Xq);

% Use interp1 on the distance maps, final masks will have +ve distance
BWout = reshape((interp1(X, D, Xq, varargin{interp1ArgInds}) >= 0)', prevSize);

% Undo permute if interpDim wasn't last dimension
if interpDim~=maxDim
    BWout = ipermute(BWout, dimPerm);
end


function [X,BW,Xq,interpDim,interp1ArgInds] = parseInputs(varargin)
nArgs = nargin;

BWargNo = find(cellfun(@islogical, varargin),1);
if isempty(BWargNo) || BWargNo>2
    error('interpmask:args','First or second argument must be a stack of logical masks');
end
BW = varargin{BWargNo};
Xq = varargin{BWargNo+1};

idArgNo = find(strcmpi('interpdim',varargin),1,'last');
if isempty(idArgNo)
    interpDim = ndims(BW);
    interp1ArgInds = BWargNo+2:nArgs;
else
    interpDim = varargin{idArgNo+1};
    interp1ArgInds = BWargNo+4:nArgs;
end

if BWargNo==1
    X = 1:size(BW,interpDim);
else
    X = varargin{1};
end
