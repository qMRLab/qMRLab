function Fit = FitData(data, Model, wait , Fittmp)
%         __  __ ____  _          _     
%    __ _|  \/  |  _ \| |    __ _| |__  
%   / _` | |\/| | |_) | |   / _` | '_ \ 
%  | (_| | |  | |  _ <| |__| (_| | |_) |
%   \__, |_|  |_|_| \_\_____\__,_|_.__/ 
%      |_|
% ----------------------------------------------------------------------------------------------------
% Fit = FitData( data, Model, wait, FitTempResults_filename )
% Takes 2D or 3D MTdata and returns fitted parameters maps
% ----------------------------------------------------------------------------------------------------
% Inputs
%     data                       [struct] with fields Model.MRIinputs. Contains MRI data.
%                                          data fields are array of size [x,y,z,(nT or 1)],
%                                          where x = image height, y = image width,
%                                          z = image depth and nT is the number of
%                                          data points for each voxel
%     Model                      [class]  Model object
%     wait                       [binary] display a wait bar?
%     FitTempResults_filename    [string] filename of a temporary fitting file
%
% Output
%     Fit                        [struct] with fitted parameters
%
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Fran??ois Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :
%
% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------

% Before fitting, do a sanity check on the input data and protocol
Model.sanityCheck(data);

tStart = tic;
tsaved = 0;
tsavedwb = 0;

h=[]; hwarn=[];
if moxunit_util_platform_is_octave % ismethod not working properly on Octave
    try, Model = Model.Precompute; end
    try, Model = Model.PrecomputeData(data); end

else
    if ismethod(Model,'Precompute'), Model = Model.Precompute; end
    if ismethod(Model,'PrecomputeData'), Model = Model.PrecomputeData(data); end
end

% NaN in Mask
if isfield(data,'Mask') && (~isempty(data.Mask)) && any(isnan(data.Mask(:)))
    data.Mask(isnan(data.Mask))=0;
    msg = 'NaNs will be set to 0. We recommend you to check your mask.';
    titlemsg = 'NaN values detected in the Mask';
    if exist('wait','var') && (wait)
        hwarn = warndlg(msg,titlemsg);
    end
    fprintf('\n')
    warning(titlemsg)
    fprintf('%s\n\n',msg)
end

if Model.voxelwise % process voxelwise
    %############################# INITIALIZE #################################
    % Get dimensions
    MRIinputs = fieldnames(data);
    MRIinputs(structfun(@isempty,data))=[];
    MRIinputs(strcmp(MRIinputs,'hdr'))=[];
    qDataIdx=find((strcmp(Model.MRIinputs{1},MRIinputs')));
    qData = double(data.(MRIinputs{qDataIdx}));
    x = 1; y = 1; z = 1;
    [x,y,z,nT] = size(qData);

    % Arrange voxels into a column
    nV = x*y*z;     % number of voxels
    for ii = 1:length(MRIinputs)
        if ndims(data.(MRIinputs{ii})) == 4
            data.(MRIinputs{ii}) = reshape(data.(MRIinputs{ii}),nV,nT);
        elseif ~isempty(data.(MRIinputs{ii}))
            data.(MRIinputs{ii}) = reshape(data.(MRIinputs{ii}),nV,1);
        end
    end

    % Load FitTempResults
    if exist('Fittmp','var')
        Fit = load(Fittmp);
        computed = Fit.computed(:);
        fields = Fit.fields;
    else
        computed = false(nV,1);
    end


   
    if isfield(data,'Mask') && (~isempty(data.Mask))
        
        % Set NaN values to zero if there are any 
        if any(isnan(data.Mask(:)))
           data.Mask(isnan(data.Mask))=0;
            msg = 'NaNs will be set to 0. We recommend you to check your mask.';
            titlemsg = 'NaN values detected in the Mask';
            if exist('wait','var') && (wait)
                hwarn = warndlg(msg,titlemsg);
            end
            fprintf('\n')
            warning(titlemsg)
            fprintf('%s\n\n',msg) 
        end
        
        % Find voxels that are not empty
        Voxels = find(all(data.Mask & ~computed,2));    
        
    else
        Voxels = find(~computed)';
    end
    numVox = length(Voxels);
    
    % Travis?
    if isempty(getenv('ISTRAVIS')) || ~str2double(getenv('ISTRAVIS')), ISTRAVIS=false; else ISTRAVIS=true; end

    %############################# FITTING LOOP ###############################
    % Create waitbar
    if exist('wait','var') && (wait)
        h = waitbar(0,'0%','Name','Fitting data','CreateCancelBtn',...
            'if ~strcmp(get(gcbf,''Name''),''canceling...''), setappdata(gcbf,''canceling'',1); set(gcbf,''Name'',''canceling...''); else delete(gcbf); end');
        setappdata(h,'canceling',0)
    end

    if (isempty(h))
        disp('=============== qMRLab::Fit ======================')
        disp(['Operation has been started: ' Model.ModelName]);
    end
    fitFailedCounter = 0;
    tic;
    for ii = 1:numVox
        vox = Voxels(ii);
        
        % Get current voxel data
        for iii = 1:length(MRIinputs)
            M.(MRIinputs{iii}) = data.(MRIinputs{iii})(vox,:)';
        end
        if isfield(data,'hdr'), M.hdr = data.hdr; end
        % Fit data
        try
            tempFit = Model.fit(M);
            fitFailed = false;
        catch err
            [xii,yii,zii] = ind2sub([x y z],vox);
            %fprintf(2, 'Error in voxel [%d,%d,%d]: %s\n',xii,yii,zii,err.message);
            if fitFailedCounter < 10
              cprintf('magenta','>> Solution not found for voxel [%d,%d,%d]: %s\n',xii,yii,zii,err.message);
            elseif fitFailedCounter == 11
              cprintf('blue','%s','Errorenous fit warnings will be silenced for this process.');
              if ~isfield(data,'Mask')
                  cprintf('orange','%s','>> Please condiser providing a binary mask to accelerate fitting.');
              else
                  cprintf('orange','%s','>> The provided mask probably contains some background voxels.'); 
              end
            end
            
            fitFailed = true;
            fitFailedCounter = fitFailedCounter + 1;
        end
        % The variable tempFit won't be declared until the 
        % first successful fit. 
        if exist('tempFit','var')
            if isempty(tempFit), Fit=[]; return; end
        end

        % initialize the outputs
        if ~exist('Fit','var') && ~fitFailed
            fields =  fieldnames(tempFit)';

            for ff = 1:length(fields)
                Fit.(fields{ff}) = nan(x,y,z,length(tempFit.(fields{ff})));
            end
            Fit.fields = fields;
            Fit.computed = zeros(x,y,z);
        end

        % Assign current voxel fitted values
        if ~fitFailed
            for ff = 1:length(fields)
                [xii,yii,zii] = ind2sub([x,y,z],vox);
                Fit.(fields{ff})(xii,yii,zii,:) = tempFit.(fields{ff});
            end 
        end
        
        Fit.computed(vox) = 1;
        
        %  save temp file every 5min
        telapsed = toc(tStart);
        if (mod(floor(telapsed/60),5) == 0 && (telapsed-tsaved)/60>5) %
            tsaved = telapsed;
            save('FitTempResults.mat', '-struct','Fit');
        end
        
        % Update waitbar every sec
        if (isempty(h))
            % j_progress(ii) Feature removed temporarily until logs are implemented ? excessive printing is a nuissance in Jupyter Notebooks, and slow down processing
            %            fprintf('Fitting voxel %d/%d\r',ii,l);

        else
            if getappdata(h,'canceling');  break;  end  % Allows user to cancel
            if (telapsed-tsavedwb)>1 % Update waitbar every sec
                tsavedwb = telapsed; 
                waitbar(ii/numVox, h, sprintf('Fitting voxel %d/%d (%d errors)', ii, numVox, fitFailedCounter));
            end
        end
        
        if ISTRAVIS && ii>2
            try
                Fit = load(fullfile('.','FitResults','FitResults.mat'));
            end
            break;
        end
    end
    toc;
    disp(['Operation has been completed: ' Model.ModelName]);
    disp('==================================================')
    
else % process entire volume
    
    % AK: Commenting out this block. Modal window is actually annoying.
    %{
    if exist('wait','var') && (wait) && not(isdeployed)
        hMSG = msgbox({'Fitting has been started. Please wait until this window disappears.'; ...
        ' '; 'You can follow outputs from the CommandWindow'});

        set(hMSG,'WindowStyle','modal')
        set(hMSG,'pointer', 'watch'); drawnow;
    end
    %}
    
    % Mask data before fitting
    if isfield(data,'Mask') && (~isempty(data.Mask))
        fields =  fieldnames(data);
        for ff = 1:length(fields)
             
             % Developer note: 
             % Keeping this verbose statement as an example of how 
             % previous matlab versions can fail to produce the 
             % expected functionality. Issue #331. 
                
             if ~moxunit_util_platform_is_octave
                 
                if ~isempty(data.(fields{ff})) 
                 if verLessThan('matlab','9.0')
                     
                     % Introduced in R2007a
                     data.(fields{ff}) = bsxfun(@times, data.(fields{ff}),double(data.Mask>0));
                     
                 else
                      % Introduced in 2016
                     data.(fields{ff}) = data.(fields{ff}) .* double(data.Mask>0);
                 end
                end
                
             else % If Octave 
                 
                 if ~isempty(data.(fields{ff}))
                  data.(fields{ff}) = data.(fields{ff}) .* double(data.Mask>0);
                 end
                 
             end
             
        end
    end
    disp('=============== qMRLab::Fit ======================')
    disp(['Operation has been started: ' Model.ModelName]);
    tic;
    Fit = Model.fit(data);
    Fit.fields = fieldnames(Fit);
    toc;
    disp(['Operation has been completed: ' Model.ModelName]);
    if ~moxunit_util_platform_is_octave && ~isempty(findobj(0, 'tag', 'qMRILab'))
        
        disp('Loading outputs to the GUI may take some time.');    
    
    end
    disp('==================================================')
end
% delete waitbar
%if (~isempty(hMSG) && not(isdeployed));  delete(hMSG); end
if ishandle(hwarn), delete(hwarn); end

Fit.Time = toc(tStart);
Fit.Protocol = Model.Prot;
Fit.Model = Model;
Fit.Version = qMRLabVer;
if exist(fullfile('.','FitTempResults.mat'),'file')
    delete FitTempResults.mat
end
end
