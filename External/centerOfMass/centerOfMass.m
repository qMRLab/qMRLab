function varargout = centerOfMass(A,varargin)
% CENTEROFMASS finds the center of mass of the N-dimensional input array
%
%   CENTEROFMASS(A) finds the gray-level-weighted center of mass of the
%   N-dimensional numerical array A. A must be real and finite. A warning
%   is issued if A contains any negative values. Any NaN elements of A will
%   automatically be ignored. CENTEROFMASS produces center of mass
%   coordinates in units of pixels. An empty array is returned if the
%   center of mass is undefined.
%
%   The center of mass is reported under the assumption that the first
%   pixel in each array dimension is centered at 1.
%
%   Also note that numerical arrays other than DOUBLE and SINGLE are
%   converted to SINGLE in order to prevent numerical roundoff error.
%
%   Examples:
%       A = rgb2gray(imread('saturn.png'));
%       C = centerOfMass(A);
%
%       figure; imagesc(A); colormap gray; axis image
%       hold on; plot(C(2),C(1),'rx')
%
%   See also: 
%
%

%
%   Jered R Wells
%   2013/05/07
%   jered [dot] wells [at] gmail [dot] com
%
%   v1.0
%
%   UPDATES
%       YYYY/MM/DD - jrw - v1.1
%
%

%% INPUT CHECK
narginchk(0,1);
nargoutchk(0,1);
fname = 'centerOfMass';

% Checked required inputs
validateattributes(A,{'numeric'},{'real','finite'},fname,'A',1);

%% INITIALIZE VARIABLES
A(isnan(A)) = 0;
if ~(strcmpi(class(A),'double') || strcmpi(class(A),'single'))
    A = single(A);
end
if any(A(:)<0)
    warning('MATLAB:centerOfMass:neg','Array A contains negative values.');
end

%% PROCESS
sz = size(A);
nd = ndims(A);
M = sum(A(:));
C = zeros(1,nd);
if M==0
    C = [];
else
    for ii = 1:nd
        shp = ones(1,nd);
        shp(ii) = sz(ii);
        rep = sz;
        rep(ii) = 1;
        ind = repmat(reshape(1:sz(ii),shp),rep);
        C(ii) = sum(ind(:).*A(:))./M;
    end
end

% Assemble the VARARGOUT cell array
varargout = {C};

end % MAIN