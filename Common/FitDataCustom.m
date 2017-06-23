function Fit = FitDataCustom( data, Model, wait )

% ----------------------------------------------------------------------------------------------------
% Fit = FitData( data, Model, wait )
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
% If you use qMRLab in your work, please cite :

% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------

tic;
if Model.voxelwise % process voxelwise
    %############################# INITIALIZE #################################
    % Get dimensions
    MRIinputs = fieldnames(data);
    MRIinputs(structfun(@isempty,data))=[];
    qData = double(data.(MRIinputs{1}));
    dim = ndims(qData);
    x = 1; y = 1; z = 1;
    switch dim
        case 4
            [x,y,z,nT] = size(qData);
        case 3
            [x,y,nT] = size(qData);
        case 2
            nT = length(qData);
    end
    
    % Arrange voxels into a column
    nV = x*y*z;     % number of voxels
    for ii = 1:length(MRIinputs)
        if ndims(data.(MRIinputs{ii})) == 4
            data.(MRIinputs{ii}) = reshape(data.(MRIinputs{ii}),nV,nT);
        elseif ~isempty(data.(MRIinputs{ii}))
            data.(MRIinputs{ii}) = reshape(data.(MRIinputs{ii}),nV,1);
        end
    end
    
    % Find voxels that are not empty
    if isfield(data,'Mask') && (~isempty(data.Mask))
        Voxels = find(all(data.Mask,2));
    else
        Voxels = (1:nV)';
    end
    l = length(Voxels);
    
    
    %############################# FITTING LOOP ###############################
    % Create waitbar
    h=[];
    if exist('wait','var') && (wait)
        h = waitbar(0,'0%','Name','Fitting data','CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
        setappdata(h,'canceling',0)
    end
    
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
        for iii = 1:length(MRIinputs)
            M.(MRIinputs{iii}) = data.(MRIinputs{iii})(vox,:)';
        end
        % Fit data
        tempFit = Model.fit(M);
        if isempty(tempFit), Fit=[]; return; end
        
        % initialize the outputs
        if ii==1 
            fields =  fieldnames(tempFit)';
            
            for ff = 1:length(fields)
                Fit.(fields{ff}) = zeros(x,y,z,length(tempFit.(fields{ff})));
            end
            Fit.fields = fields;
            Fit.computed = zeros(x,y,z);
        end
        
        % Assign current voxel fitted values
        for ff = 1:length(fields)
            [xii,yii,zii] = ind2sub([x,y,z],vox);
            Fit.(fields{ff})(xii,yii,zii,:) = tempFit.(fields{ff});
        end
        
        Fit.computed(ii) = 1;
        
        %-- save temp file every 20 voxels
        if(mod(ii,20) == 0)
            save('FitTempResults.mat', '-struct','Fit');
        end
    end
    
    % delete waitbar
    if (~isempty(h));  delete(h); end
    
else % process entire volume
    Fit = Model.fit(data);
    Fit.fields = fieldnames(Fit);
end
Fit.Time = toc
Fit.Protocol = Model.Prot;

end