function Fit = FitData( data, Protocol, FitOpt, Method, wait )

% ----------------------------------------------------------------------------------------------------
% Fit = FitData( data, Protocol, FitOpt, Method, wait )
% Takes 2D or 3D MTdata and returns fitted parameters maps
% ----------------------------------------------------------------------------------------------------
% data = struct with fields 'MTdata', and optionnaly 'Mask','R1map','B1map','B0map'
% Output : Fit structure with fitted parameters
%
% MTdata is an array of size [x,y,z,nT], where x = image height, y = image
% width, z = image depth and Nt is the number of data points for each voxel
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMTLab in your work, please cite :

% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------


%############################# INITIALIZE #################################
% Get dimensions
MTdata = double(data.MTdata);
dim = ndims(MTdata);
x = 1; y = 1; z = 1;
switch dim
    case 4
        [x,y,z,nT] = size(MTdata);
    case 3
        [x,y,nT] = size(MTdata);
    case 2
        nT = length(MTdata);
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
    Fit.Mask = single(data.Mask);
    Mask = reshape(data.Mask,nV,1);
    MTdata = MTdata.*repmat(Mask,[1,nT]);
end

% Find voxels that are not empty
Voxels = find(all(MTdata,2));
l = length(Voxels);

if (~isempty(data.R1map));  R1map = reshape(double(data.R1map),nV,1); end

if (~isempty(data.B1map));  B1map = reshape(double(data.B1map),nV,1); end

if (~isempty(data.B0map));  B0map = reshape(double(data.B0map),nV,1); end

FitOpt.R1 = [];
FitOpt.B1 = [];
FitOpt.B0 = [];

%############################# FITTING LOOP ###############################
% Create waitbar
h=[];
if (wait)
    h = waitbar(0,'0%','Name','Fitting data','CreateCancelBtn',...
        'setappdata(gcbf,''canceling'',1)');
    setappdata(h,'canceling',0)
end

tic;
for ii = 1:l
    vox = Voxels(ii);
    
    % Update waitbar
    if (isempty(h))
        fprintf('Fitting voxel %d/%d\r',ii,l);
    else
        if getappdata(h,'canceling');  break;  end  % Allows user to cancel
        waitbar(ii/l, h, sprintf('Fitting voxel %d/%d', ii, l));
    end
    
    % Get current voxel data
    M(:,1) = MTdata(vox,:);
    
    if (FitOpt.R1map && ~isempty(data.R1map)); FitOpt.R1 = R1map(vox); end
    
    if (~isempty(data.B1map)); FitOpt.B1 = B1map(vox); end
    
    if (~isempty(data.B0map)); FitOpt.B0 = B0map(vox); end
    
    if (isfield(FitOpt,'PreviousFit'))
        names = FitOpt.names;
        for ff = 1:length(names)
            FitOpt.st(ff) = FitOpt.PreviousFit.(names{ff})(vox);
        end
    end
    
    % Fit data
    switch Method
        case 'SIRFSE'; tempFit = SIRFSE_fit(M, Protocol, FitOpt);
        case 'bSSFP';  tempFit = bSSFP_fit(M, Protocol, FitOpt);
        case 'SPGR';   tempFit = SPGR_fit(M, Protocol, FitOpt );
    end
        
    % Assign current voxel fitted values
    for ff = 1:length(fields)
        Fit.(fields{ff})(vox) = tempFit.(fields{ff});
    end
    
    Fit.computed(ii) = 1;

    %-- save temp file every 20 voxels
    if(mod(ii,20) == 0)
      save('FitTempResults.mat', '-struct','Fit');
    end
end

if (~isempty(h));  delete(h); end

% Reshape Fit
for ff = 1:length(fields)
    Fit.(fields{ff}) = reshape(Fit.(fields{ff}),x,y,z);
end
Fit.computed = reshape(Fit.computed,x,y,z);

Fit.Time = toc
Fit.Protocol = Protocol;
Fit.FitOpt = FitOpt;

end