function Fit = FitDataPar( data, Protocol, FitOpt, Method, wait )

%FITDATA Takes 2D or 3D MTdata and returns fitted parameters maps
%   data is a struct containing fields MTdata and optionnal R1map, Mask,
%   B1map and B0map.

% MTdata is an array of size [x,y,z,nT], where x = image height, y = image
% width, z = image depth and Nt is the number of data points for each voxel


%############################# INITIALIZE #################################
% Get dimensions
MTdata = data.MTdata;
dim = ndims(MTdata);
x = 1; y = 1; z = 1;
switch dim
    case 4
        [x,y,z,nT] = size(MTdata);
    case 3
        [x,y,nT] = size(MTdata);
    case 2
        [x,nT] = size(MTdata);
end

% Arrange voxels into a column
nV = x*y*z;     % number of voxels
MTdata = reshape(MTdata,nV,nT);
M = zeros(nT,1);

switch Method
    case 'SIRFSE'; fields = {'F';'kf';'kr';'R1f';'R1r';'Sf';'Sr';'M0f';'M0r';'resnorm'};        
    case 'bSSFP';  fields = {'F';'kf';'kr';'R1f';'R1r';'T2f';'M0f';'M0r';'resnorm'};        
    case 'SPGR';   fields = {'F';'kf';'kr';'R1f';'R1r';'T2f';'T2r';'resnorm'};
end

for ii = 1:length(fields)
    Fit.(fields{ii}) = zeros(x,y,z);
    Fit.(fields{ii}) = reshape(Fit.(fields{ii}),nV,1);
end
Fit.fields = fields;
Fit.computed = Fit.(fields{1});

% Apply mask
if (~isempty(data.Mask))
    Mask = reshape(data.Mask,nV,1);
    MTdata = MTdata.*repmat(Mask,[1,nT]);
end

% Find voxels that are not empty
Voxels = find(all(MTdata,2));
l = length(Voxels);

if (~isempty(data.R1map));  R1map = reshape(data.R1map,nV,1); end

if (~isempty(data.B1map));  B1map = reshape(data.B1map,nV,1); end

if (~isempty(data.B0map));  B0map = reshape(data.B0map,nV,1); end

FitOpt.R1 = [];
FitOpt.B1 = [];
FitOpt.B0 = [];

% Build FitOpt array to be able to use parfor
fitopt = cell(nV,1);
% fitopt = struct;
names = FitOpt.names;
for ii = 1:nV
    fitopt{ii} = FitOpt;
    if (FitOpt.R1map && exist('R1map','var')); fitopt{ii}.R1 = R1map(ii); end
    
    if (exist('B1map','var')); fitopt{ii}.B1 = B1map(ii); end
    
    if (exist('B0map','var')); fitopt{ii}.B0 = B0map(ii); end

    if (isfield(FitOpt,'PreviousFit'))
        for ff = 1:length(names)
            fitopt{ii}.st(ff) = FitOpt.PreviousFit.(names{ff})(ii);
        end
    end
end

%############################# FITTING LOOP ###############################

parfor_progress(l);
tic;

parfor ii = 1:nV
    if (Mask(ii)==0); continue; end;

    % Get current voxel data
    M = MTdata(ii,:);
    
    % Fit data
    switch Method
        case 'SIRFSE'; tempFit{ii} = SIRFSE_fit(M, Protocol, fitopt{ii});
        case 'bSSFP';  tempFit{ii} = bSSFP_fit(M, Protocol, fitopt{ii});
        case 'SPGR';   tempFit{ii} = SPGR_fit(M, Protocol, fitopt{ii} );
    end
        
%     %-- save temp file every 20 voxels
%     if(mod(ii,20) == 0)
%       save('FitTempResults.mat', '-struct','Fit');
%     end
    tempFit{ii}.computed = 1;
    parfor_progress;
end

parfor_progress(0);

for ii = 1:nV
    % Assign fitted values
    for ff = 1:length(fields)
        Fit.(fields{ff})(ii) = tempFit{ii}.(fields{ff});
        Fit.computed(ii) = tempFit{ii}.computed;
    end
end

% Reshape Fit
for ff = 1:length(fields)
    Fit.(fields{ff}) = reshape(Fit.(fields{ff}),x,y,z);
end
Fit.computed = reshape(Fit.computed,x,y,z);

Fit.Time = toc
Fit.Protocol = Protocol;
Fit.FitOpt = FitOpt;

end