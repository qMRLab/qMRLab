function Fit = ParFitData(data, Model,varargin)
%         __  __ ____  _          _
%    __ _|  \/  |  _ \| |    __ _| |__
%   / _` | |\/| | |_) | |   / _` | '_ \
%  | (_| | |  | |  _ <| |__| (_| | |_) |
%   \__, |_|  |_|_| \_\_____\__,_|_.__/
%      |_|
% -------------------------------------------------------------------------
% Fit = ParFitData(data, Model,varargin)
% Takes 2D or 3D qMRI data and returns fitted parameters maps
% -------------------------------------------------------------------------
% Required inputs:
%
%     data                          Struct with fields containing the data
%                                   for quantitative parameter estimation.
%                                   See details below. (struct)    
%
%     Model                         An object instantiated from a qMRLab
%                                   model class. (object)
%
% Output:
%
%     Fit                           Struct with fields containing the
%                                   quantitative maps. (struct)
%
% 
% ParFitData(___,PARAM1, VAL1, PARAM2, VAL2,___)
%
% Optional parameters include:
%
%
%   'AutosaveEnabled'               Enable/disable autosave of the fitted
%                                   parameters at a specified time interval.
%                                   Default: true (logical)
%
%   'AutosaveInterval'              Time interval (in minutes) at which
%                                   the fitted parameters will be saved.
%                                   Default: 5 (int)
%                                   
%
%   'RecoverDirectory'              Directory containing previously
%                                   autosaved data. When provided, the
%                                   process will pick up from where it
%                                   was left off at the time of the latest
%                                   autosave. 
%                                   Default: [] (string)
%
% Notes about data: 
%
%    Field names                    Field names of the `data` struct MUST 
%                                   be identical with that of the MRIinputs
%                                   property of the respective Model.
%
%    Input dimensions               Extents of the volume will be inferred
%                                   from the first 2/3 dimensions of the
%                                   input data [x, y, (z), __].
%                          
%    2D/3D input data               If multiple intensity values are stored
%    multiple scalars               at each voxel (for example, voxel
%                                   intensity values at different TIs),
%                                   these values MUST be stored from 4th
%                                   dimension onwards.
%  
%                                   2D inputs [x, y, 1, nT, __]           
%                                   3D inputs [x, y, z, nT, __]
%                                             
%    2D/3D input data
%    with a single scalar           If a single intensity value is stored
%                                   at each voxel (for example, B1map,
%                                   Mask, R1map) the inputs can be provided
%                                   without a singleton dimension.
%                                   
%                                   2D inputs [x, y]
%                                   3D inputs [x, y, z]
%
% Functionality:
%
%     The input data will be split into N chunks to be proccessed in N cores.
%     In GUI, this script will be run instead of FitData if parpool object 
%     exists. In CLI, can be called similarly with FitData in batch examples.
%     Again, parpool must be initialized first.
%
%     Not compatible for Octave yet, which requires refactoring this script
%     for parcellfun. In Octave, parfor is the same with for, just there for
%     compatibility. Warning is set in case this function is called from
%     Octave.
%
% -------------------------------------------------------------------------
% Written by: Agah Karakuzu
% -------------------------------------------------------------------------
% References
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F.,
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab:
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343
% -------------------------------------------------------------------------


p = inputParser();

%Input parameters conditions
validData  = @(x) exist('x','var') && isstruct(x);
validModel = @(x) exist('x','var') && isobject(x);
validDir   = @(x) exist(x,'dir');

addRequired(p,'data',validData);
addRequired(p,'Model',validModel);
addParameter(p,'RecoverDirectory',[],validDir);
addParameter(p,'AutosaveInterval',5,@isnumeric);
addParameter(p,'AutosaveEnabled',true,@isnumeric);

parse(p,data,Model,varargin{:});

% Extract parsed inputs and delete the parser object
data = p.Results.data;
Model = p.Results.Model;
saveInterval = ceil(p.Results.AutosaveInterval);
recoveryDir  = p.Results.RecoverDirectory;
isAutosave = p.Results.AutosaveEnabled;
clear('p');

% Before fitting, do a sanity check on the input data and protocol
Model.sanityCheck(data);


if moxunit_util_platform_is_octave
    nW = 1;
    cprintf('red','<< ! >> Data will be processed serially! ParFitData has not been implemented for  %s yet. \n','Octave');
else
    % In matlab, whenever this script is called, a parallel pool
    % should be available.
    p = gcp('nocreate');
    if isempty(p)
        p = gcp;
    end
    
    nW = p.NumWorkers;
end

h=[]; hwarn=[];
if moxunit_util_platform_is_octave % ismethod not working properly on Octave
    try Model = Model.Precompute; end
    try Model = Model.PrecomputeData(data); end
    
else
    if ismethod(Model,'Precompute'), Model = Model.Precompute; end
    if ismethod(Model,'PrecomputeData'), Model = Model.PrecomputeData(data); end
end

% Zero-out NaN values in Mask if they exist.
if isfield(data,'Mask') && (~isempty(data.Mask)) && any(isnan(data.Mask(:)))
    data.Mask(isnan(data.Mask))=0;
    msg = 'NaNs will be set to 0. We recommend you to check your mask.';
    titlemsg = 'NaN values detected in the Mask';
    fprintf('\n')
    warning(titlemsg)
    fprintf('%s\n\n',msg)
end

if Model.voxelwise % process voxelwise
    
    tmpFolderName = ['.' filesep 'ParFitTempResults_' datestr(now,'yyyy-mm-dd_HH-MM')];

    % Get dimensions
    MRIinputs = fieldnames(data);
    MRIinputs(structfun(@isempty,data))=[];
    MRIinputs(strcmp(MRIinputs,'hdr'))=[];
    qDataIdx=find((strcmp(Model.MRIinputs{1},MRIinputs')));
    qData = double(data.(MRIinputs{qDataIdx}));
    x = 1; y = 1; z = 1;
    [x,y,z,nT] = size(qData);
    clear('qData'); % Flush, no need.
    
    % Vectorize input data
    % nV is the number of "volumetric" voxels
    % nT is the number of components that each volumetric voxel contain.
    % Even in 2D data, we have z=1 defined along with x and y.
    nV = x*y*z;     % number of voxels
    for ii = 1:length(MRIinputs)
        if ndims(data.(MRIinputs{ii})) == 4
            data.(MRIinputs{ii}) = reshape(data.(MRIinputs{ii}),nV,nT);
        elseif ~isempty(data.(MRIinputs{ii}))
            data.(MRIinputs{ii}) = reshape(data.(MRIinputs{ii}),nV,1);
        end
    end
    
    
    % Reduce the data (nV) based on the presence of a Mask.
    if isfield(data,'Mask') && (~isempty(data.Mask))
        
        % Set NaN values to zero if there are any
        if any(isnan(data.Mask(:)))
            data.Mask(isnan(data.Mask))=0;
            msg = 'NaNs will be set to 0. We recommend you to check your mask.';
            titlemsg = 'NaN values detected in the Mask';
            fprintf('\n')
            warning(titlemsg)
            fprintf('%s\n\n',msg)
        end
        
        % Store voxel indexes that are not empty.
        Voxels = find(all(data.Mask,2));    
        
        % Only keep data nV voxels (needless to say along with their
        % respective nT, hence the (:)), that are included in the mask.
        % Here, masking is made on linearized data again.
        for iii = 1:length(MRIinputs)
            data.(MRIinputs{iii}) = data.(MRIinputs{iii})(data.Mask==1,:);
        end
        
        % Before mapping remaining data on the cores, reduct processed
        % data from the whole if exists. This corresponds to removing
        % linearized indexes from voxels!
        
        bypassLoad = true; % Initialize
        
        % If recovery data is found
        if ~isempty(recoveryDir)
            
            % First, reduce data from the WHOLE list of linearized indexes
            % (1:nV). This will also validate whether the loaded data is 
            % compatible with the current process.
            [Voxels_reduced, bypassLoad] = rmAutoSavedIndexes(recoveryDir,1:nV,x,y,z, Model);
            
            % Now we have the linearized indexes of the remaining data.
            % From this remaining data, we will discard those intersecting
            % with the mask==1 indexes, which are assigned to the Voxels 
            % variable at L202. We should do this only when the loaded data
            % is valid. 
            
            if ~bypassLoad
                [Voxels_masked_reduced,validIdx] = intersect(Voxels,Voxels_reduced,'stable');
                for iii = 1:length(MRIinputs)
                    % Reduce the data in correspondance with the reduxed
                    % idx, so that we cam map it properly later on.
                    data.(MRIinputs{iii}) = data.(MRIinputs{iii})(validIdx,:);
                end
            end
        end

        % Map data into nW number of cores. For example, if the data has
        % 1000 nV after all the reductions, and the parpool has 4 cores,
        % parM will be a struct array of length 4, where each struct
        % containing 250 nV to process. One important thing is that we keep
        % record of NativeIdx (original linearized index of nV elements
        % before the reduction), so that we can put them in the right place
        % in the image domain once the processing is completed.
        if bypassLoad
            [parM,~] = mapData(Model,data,MRIinputs,Voxels,nW);
        else
            [parM,~] = mapData(Model,data,MRIinputs,Voxels_masked_reduced,nW);
        end
    else
        % If you are not familiar with the idea of linearized indexing,
        % read below.
        
        % Small TUTORIAL in case this is confusing:
        % MATLAB linear indexing of an nD matrix of M with size [X, Y, Z] follows
        % [innermost,-->, outermost] order while vectorizing. This is how
        % sub2ind and ind2sub returns respective indexes. For example:
        % -----
        % [x, y, z] = ndgrid(1:X,1:Y,1:Z);
        % vectorized = [];
        % for kk = 1:Z
        %     for jj = 1:Y
        %         for ii = 1:X
        %             vectorized = [vectorized sub2ind([X,Y,Z],ii,jj,kk)];
        %          end
        %      end
        % end
        % -----
        % The above variable vectorized is simply 1:(X*Y*Z)! Understanding
        % Matlab/Octave linear indexing logic is fundamental to the
        % understanding of this script.
        
        Voxels = 1:nV; % Linear indexing!
        
        % Here we are doing the same thing we did above, but this time
        % we have no reduction in data by Masks.
        if ~isempty(recoveryDir)
            
            [Voxels, bypassLoad] = rmAutoSavedIndexes(recoveryDir,Voxels,x,y,z, Model);
            
            if ~bypassLoad
                for iii = 1:length(MRIinputs)
                    data.(MRIinputs{iii}) = data.(MRIinputs{iii})(Voxels,:);
                end
            end
        end
        [parM,~] = mapData(Model,data,MRIinputs,Voxels,nW);
        
    end
    
    disp('=============== qMRLab::Fit ======================')
    cprintf('magenta', '<< i >> Operation has been started:  %s \n',Model.ModelName);
    cprintf('blue',    '<< : >> Parallel:  %d workers \n',nW);
    cprintf('orange',  '<< - >> Modal windows have been disabled \n',nW);
    cprintf('blue',    '<< ! >> Temporary results will be saved every %d minutes. \n',saveInterval);
    

    
    % parfor_progress(nW); % Useless
    % Developer:
    %          You can monitor per-core performance by commenting in
    %
    % p; Par.tic; p(itPar) = Par.toc; and %figure(); plot(p); stop(p); lines.
    %
    %p = Par(nW);
    
   


    % Take functions outside the parfor not to register objects as broadcast
    % variables.
    fitfun = @Model.fit;
    fLen = length(Model.xnames);
    xnames = Model.xnames;
    modelName = Model.ModelName;
    svObj = @Model.saveObj;
    % Sending data by parallel.pool.Constant() won't make it faster for 
    % this application. The data is already sliced per core.
    
    tStart = tic;
    parfor itPar = 1:nW
        %Par.tic;
        parM(itPar).tsaved = 0;
        for ii = 1:length(parM(itPar).NativeIdx)
            
            % Get current voxel data into a struct
            % That's how Model,fit functions are designed. They all fit
            % a single voxel data that comes with all the needed info
            % in a struct.
            Mi = struct();
            for iii = 1:length(MRIinputs)
                % Using dynamic field assignments to populate a single voxel
                % struct to be sent to Model's fit method.
                Mi.(MRIinputs{iii}) = parM(itPar).(MRIinputs{iii})(ii,:)';
            end
            
            % Fit data
            % As you noted, we keep slicing inputs and outputs with "itPar"
            % In MATLAB's parallel computing nomenclature, these are called
            % sliced variables, a good way to inform parallel task manager
            % about how to manage threads.
            % Collect computed indexes
            parM(itPar).computedIdx(ii) = parM(itPar).NativeIdx(ii);
            try
                parM(itPar).tempFit = fitfun(Mi);
                parM(itPar).fitFailed = false;
            catch err
                
                % Especially when there is not a mask, many many fits will fail.
                % Limit the number of warnings, as there is no point in showing
                % them all.
                if parM(itPar).fitFailedCounter < ceil(10/nW)
                    
                % ind2sub converts linearized indezes to matrix indexes
                % Remember that nativeidx stores the original linearized
                % indices
                    [xii,yii,zii] = ind2sub([x y z],parM(itPar).NativeIdx(ii));
                    % It is important that errmsg is explicitly assigned here but not passed in-line.
                    % These are recognized as temporary variables by MATLAB
                    % parpool, which manages them fairly good.
                    errmsg = err.message;
                    cprintf('magenta','Solution not found for the voxel [%d,%d,%d]: %s \n',xii,yii,zii,errmsg);
                elseif parM(itPar).fitFailedCounter == ceil(11/nW)
                    cprintf('blue','Message from worker %d: Errorenous fit warnings are now silenced.',itPar);
                end
                
                parM(itPar).fitFailed = true;
                parM(itPar).fitFailedCounter = parM(itPar).fitFailedCounter + 1;
            end
            
            % The variable tempFit won't be non-numeric and non-empty 
            % untill the first successful fit.
            % I casted it as numeric on decleration in order not to defeat
            % the purpose of the condition L375.

            %if  ~isempty(parM(itPar).tempFit)
                
                % AK: I removed this, never hit. 
                %if isempty(parM(itPar).tempFit);  parM(itPar).Fit=[]; error('Fatal fit.'); end
                
                %if ~parM(itPar).firstHit
                    % Initialize outputs fields
                    % This happens only once.
                    %parM(itPar).fields =  fieldnames(parM(itPar).tempFit)';
                    
                    %parM(itPar).Fit.fields = parM(itPar).fields;
                    %parM(itPar).firstHit = true;
                %end
                
           %end
            
            % If fit is successful
            if ~parM(itPar).fitFailed
                
                for ff = 1:fLen
                    cur_field = xnames{ff};
                    %[xii,yii,zii] = ind2sub([x,y,z],parM(itPar).NativeIdx(ii));
                    parM(itPar).Fit.(cur_field)(1,ii) = parM(itPar).tempFit.(cur_field);
                end
                
            end
            
            % If fit is not successful, the value is NaN already.
            
            %  Autosave results every 5 minutes.
            %  Some models are painfully slow, it is of value to keep what
            %  you've processed in case things go sideways.
            
            %  Notice that this is again handled in a "sliced" manner
            if isAutosave
                telapsed = toc(tStart);
                if (mod(floor(telapsed/60),saveInterval) == 0 && (telapsed-parM(itPar).tsaved)/60>saveInterval)

                    if ~exist(tmpFolderName, 'dir')
                        mkdir(tmpFolderName);
                    end

                    if ~exist([tmpFolderName filesep modelName '.qmrlab.mat'], 'file')
                        % We need some small navigation as saveObj saves to
                        % the current directory only for now.
                        orDir = pwd;
                        cd(tmpFolderName);
                        svObj();
                        cd(orDir);
                    end

                    parM(itPar).tsaved = telapsed;
                    % save function cannot be called from parfor directly.
                    parSaveTemp(parM(itPar).Fit,tmpFolderName,itPar);
                    parM(itPar).tsaved = telapsed;
                end
            end
           
        end
         
        %parfor_progress;
        %p(itPar) = Par.toc;
        %updateParallel();
    end % Parallelize
    %parfor_progress(0);
    toc(tStart);
    %stop(p);
    %figure(); plot(p);
    cprintf('magenta','<< * >> Operation has been completed:  %s \n',Model.ModelName);
    cprintf('blue','<< i >> FitResults will be saved to your %s \n','working directory:');
    cprintf('blue','      - If specified in the GUI, to the %s \n','Path Data.');
    cprintf('blue','      - Otherwise at %s \n',pwd);
    disp('==================================================')
    

else % process entire volume not a parfor case
    
    
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


Fit.Time = toc(tStart);
Fit.Protocol = Model.Prot;
Fit.Model = Model;
Fit.Version = qMRLabVer;

% Parse data back into the volumetric format
% after a voxelwise fit has been
% completed.
if Model.voxelwise
    
    Fit.fields = fieldnames(parM(1).Fit);
    
    for ii = 1:length(Fit.fields)
        cur_field = Fit.fields{ii};
        Fit.(cur_field) = zeros(x,y,z);
    end
    
    % If there is autosaved data, collect them!
    % UPDATE
    if ~isempty(recoveryDir) && ~bypassLoad
        Fit = patchData(Fit,recoveryDir,x,y,z);
    end
    
    for jj = 1:length(parM)
        for ii = 1:length(Fit.fields)
            cur_field = Fit.fields{ii};
            Fit.(cur_field)(ind2sub([x,y,z],parM(jj).NativeIdx)) = parM(jj).Fit.(cur_field);
        end
    end
    

end % Voxelwise parse

end

function [parM,splits,dene] = mapData(Model,data,MRIinputs,Voxels,nW)
% Takes (reduced if masked) data struct and returns and struct array
% to be processed by eack worker.
% data: Struct
%       - If masked only those at mask ==1
%       - If autoloaded, only those autoloaded
% MRIInputs: Field from the model
% Voxels: Native linearized indices of Voxels
% nW: Number of workers to split data into

parM = struct();


splits = splitIdx(length(Voxels),nW);

dene = struct();
for iii = 1:length(MRIinputs)
    for jjj = 1:length(splits)
        % Initialize all the fields that are going to be 
        % created/assigned in the parfor, otherwise MATLAB
        % won't be able to hand it for versions older than 
        % R2019. Non-uniform struct concat issue.
        parM(jjj).(MRIinputs{iii}) = data.(MRIinputs{iii})(splits(jjj).from:splits(jjj).to,:);
        parM(jjj).NativeIdx = Voxels(splits(jjj).from:splits(jjj).to);
        parM(jjj).fitFailedCounter = 0; 
        parM(jjj).firstHit = false;
        parM(jjj).Model = Model;
        parM(jjj).tempFit = [];
        parM(jjj).tsaved = [];
        parM(jjj).fitFailed = [];
        parM(jjj).fields = [];
        parM(jjj).computedIdx = [];
        for kk=1:length(Model.xnames)
            parM(jjj).Fit.(Model.xnames{kk}) = nan(1,length(parM(jjj).NativeIdx));
        end
    end
    if isfield(data,'hdr'), parM(jjj).hdr = data.hdr; end
end



end


function out = splitIdx(x,n)
% Nothing interesting, this like some comp101 assignment :)
% 5/2 should give [3 2]
% 8/4 should give [2 2 2] (whoa what kind of sorcery is that)
% Here x is the nV (whatever remained)
% n is the number of cores.
% We return from:to indexes for each worker to collect their vagon
% from a train of linearized data.

spidx = [];
if mod(x, n) == 0
    for ii=1:n
        spidx = [spidx floor(x/n)];
    end
else
    zp = n - mod(x,n);
    pp = floor(x/n);
    for ii=1:n
        if (ii-1)>=zp
            spidx = [spidx pp+1];
        else
            spidx = [spidx pp];
        end
        
    end
end

out = struct();
prevmax = 0;
for ii=1:n
    if ii==1
        out(ii).from = 1;
        out(ii).to = spidx(ii);
        prevmax = spidx(ii);
    elseif ii==n
        out(ii).from = x-spidx(ii)+1;
        out(ii).to   = x;
    else
        out(ii).from = prevmax + 1;
        out(ii).to   = prevmax + spidx(ii);
        prevmax = out(ii).to;
    end
    
end

end

function parSaveTemp(payload,folder,worker)
% You cannot evoke this function within parfor, but you can do this.

save([folder filesep 'ParFitTempResults_worker-' num2str(worker) '.mat'], '-struct','payload');

end

function [Voxels,bypass] = rmAutoSavedIndexes(recoveryDir,Voxels,x,y,z,Model)
% Read autosaved data and drop those proccesed ones from the
% data.

% This whole thing will bypassed if there is protocol mismatch.
try
    file = dir(fullfile([recoveryDir filesep],'*.qmrlab.mat'));
    if isempty(file)
        cprintf('blue','<< %s >> --------------------------------------------------','!');
        cprintf('red','<< WARNING >> %s.qmrlab.mat cannot be find at %s:',Model.ModelName,recoveryDir);
        cprintf('red','              Cannot restore previously %s','processed data.');
        cprintf('blue','<< %s >> --------------------------------------------------','!');
        pause(3);
    end
    savedModel = qMRloadObj([recoveryDir filesep file.name]);
    bypass = false;
catch
    bypass = true;
    savedModel = [];
end
    
% Now we are going to check if saved model agrees with the current one.
try
    assertEqual(savedModel,Model);
    bypass = false;
catch
    cprintf('blue','<< %s >> --------------------------------------------------','!');
    cprintf('red','<< WARNING >> Autosaved %s data cannot be used:',Model.ModelName);
    cprintf('red','              Mismatch between the saved protocol and the %s','current one');
    cprintf('blue','<< %s >> --------------------------------------------------','!');
    pause(3); % Make sure that this is seen
    bypass = true;
end

files = dir(fullfile(recoveryDir,'ParFitTempREsults*.mat'));
if isempty(files)
    cprintf('blue','<< %s >> --------------------------------------------------','!');
    cprintf('red','<< WARNING >> Autosaved data cannot be find at %s',recoveryDir);
    cprintf('red','              The whole dataset will be %s','processed');
    cprintf('blue','<< %s >> --------------------------------------------------','!');
    bypass =  true;
end

if ~bypass
    fulLen = length(Voxels);
    those = [];
    for ii=1:length(files)
        this = load([recoveryDir filesep files(ii).name]);
        % Get native indexes only
        this = this.(this.fields{1})(:,1:3);
        % Get rid of NaN (unprocessed) parts
        that = this(all(~isnan(this),2),:);
        % Linearized indexes of that are to be removed from Voxels
        % Collect all of them
        rmLin = sub2ind([x,y,z],that(:,1),that(:,2),that(:,3));
        those = [those;rmLin];
    end
    
    % That's how you drop items from an array.
    Voxels(intersect(Voxels,those)) = [];
    
    % Display how much is done, how much is left.
    remains = ceil(100*(length(Voxels)/fulLen));
    cprintf('blue','%d%s of the data is already processed. Now processing the remaining %d%s... ',100-remains,'%',remains,'%');
end

end

function Fit = patchData(Fit,recoveryDir,x,y,z)

files = dir(fullfile(recoveryDir,'ParFitTempResults*.mat'));
for ii=1:length(files)
    thisf = load([recoveryDir filesep files(ii).name]);
    
    for jj=1:length(thisf.fields)
        cur_field = thisf.fields{jj};
        that = thisf.(cur_field);
        that = that(all(~isnan(that),2),:);
        
        [output, idx] = parseOutput(x,y,z,that);
        Fit.(cur_field)(idx) = output;

    end
end
end