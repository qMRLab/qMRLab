function [M0, T1] = Compute_M0_T1_OnSPGR(data, flipAngles, TR, b1Map, roi, verbose)
%Perform a simple linear-least squares data fit on variable flip angle SPGR data 
%
% function function [M0, T1] = Compute_M0_T1_OnSPGR(data, flipAngles, TR [, b1Map, roi, verbose])
% -----------------------------------------------------------
% INPUTS:
%   data: width x length x slices x flipAngles matrix
%   flipAngles: vector of flip angles (in degrees) corresponding to last dimension of 'data'
%   TR: Repetition time in seconds
%   b1Map: width x length x slices matrix containing relative flip angle
%         (i.e. if nominal alpha is 60 and measured alpha is 61, then b1Map = 61/60
%   roi: width x length x slices binary mask 
%   verbose: logical - for debugging


if ndims(data)<3, data = permute(data(:),[2 3 4 1]); end
[nX, nY, nZ, nFlip] = size(data);
nVox = nX*nY*nZ;

if (nargin < 4) || isempty(b1Map)
    b1Map = ones(nX, nY, nZ);
end

if nargin<5 || isempty(roi)
    roi = true(nX, nY, nZ);
end

if nargin<6
    verbose = 0;
end
 
if length(b1Map) ~= length(data(:,:,:,1)), error('B1 size is different from data size'); end
if ~islogical(roi), roi = roi>0; end

% Reshape data into 2D array so that future steps are simpler
data = reshape(data,[nVox nFlip])'; % Transpose because MATLAB is column-major
data = data(:, roi(:));
nVox = sum(roi(:));

% Large matrix with redundant values will make computations faster,
% but will also consume more memory
alpha = deg2rad(flipAngles);
if isrow(alpha), alpha = alpha'; end
alpha = repmat(alpha,[1 nVox]) .* repmat(b1Map(roi(:))', [nFlip 1]);

% Do the linear least squares fit
y = data ./ sin(alpha);
x = data ./ tan(alpha);
[fittedSlope, fittedIntercept] = LinLeastSquares(x,y);

% Assign arbitrary T1 value if fitted value in unphysical. 
% Might be better to set this to NaN so users can identify voxels where fit fails
arbitraryT1 = 0.000000000000001; % Arbitrary value in case fit fails
fittedSlope(isnan(fittedSlope)) = arbitraryT1; 
fittedIntercept(isnan(fittedIntercept)) = arbitraryT1;
fittedSlope(fittedSlope<0) = arbitraryT1;

[T1, M0] = deal(zeros(nX,nY,nZ));
M0(roi(:)) = fittedIntercept ./ (1-fittedSlope);
T1(roi(:)) = real(-TR./log(fittedSlope));
end % END OF Compute_M0_T1_OnSPGR

function [fittedSlope, fittedIntercept] = LinLeastSquares(x,y)
% Simple linear least squares fit
% Inputs:
%   - x and y, arrays of equal sizes
% The first dimension should contain the measurements
% The second dimension could be different samples (e.g. voxels)

if size(x)~=size(y), error('X and Y must have same size for linear fitting'); end
% Compute covariances, i.e. cov(x,y) and cov(x,x)
lengthX = size(x,1);
numerator = sum(x.*y) - sum(x).*sum(y) / lengthX;
denominator = sum(x.^2) - sum(x).^2 / lengthX;
% Slope is cov(x,y)/cov(x,x)
fittedSlope = numerator ./ denominator;
% Line of best fit has to pass through point (meanX, meanY)
% Use this fact to get intecept
fittedIntercept = mean(y) - fittedSlope .* mean(x);
end % END OF LinLeastSquares