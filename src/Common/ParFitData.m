function Fit = ParFitData(data, Model, autoSavedDir)
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
%     FitTempResults_filename    [string] filename of a temporary fitting f
%
% Output
%     Fit                        [struct] with fitted parameters
%
% The input data will be split into N chunks to be proccessed in N cores. In GUI, this script
% will be run instead of FitData if parpool object exists. In CLI, can be called similarly
% with FitData in batch examples. Again, parpool must be initialized first.
%
% Not compatible for Octave yet, which requires refactoring this script for parcellfun. In Octave, parfor
% is the same with for, just there for compatibility. Warning is set in case this function is called 
% directly from Octave.
%
% ----------------------------------------------------------------------------------------------------
% Written by: Agah Karakuzu
% ----------------------------------------------------------------------------------------------------
% References
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343
% ----------------------------------------------------------------------------------------------------

% Before fitting, do a sanity check on the input data and protocol
Model.sanityCheck(data);

tStart = tic;
tsaved = 0;
tsavedwb = 0;

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
    fprintf('\n')
    warning(titlemsg)
    fprintf('%s\n\n',msg)
end

if Model.voxelwise % process voxelwise
    % Create tempFolder name
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
        
        isMask = true;
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
        
        for iii = 1:length(MRIinputs)
            data.(MRIinputs{iii}) = data.(MRIinputs{iii})(data.Mask==1,:);
        end
         % Before mapping remaining data on the cores, reduct processed
         % data from the whole if exists. This corresponds to removing
         % linearized indexes from voxels!
        if exist('autoSavedDir','var')
          Voxels = rmAutoSavedIndexes(autoSavedDir,Voxels,x,y,z);
        end
        [parM,~] = mapData(Model,data,MRIinputs,Voxels,nW);
    else 
         % If no mask, simply use linear indexing because 
         % it is still important to pass NativeIdx for the uniformity 
         % of mask/noMask logic for parallelization.
         
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
         isMask = false;
         Voxels = 1:nV;
         if exist('autoSavedDir','var')
           Voxels = rmAutoSavedIndexes(autoSavedDir,Voxels,x,y,z);
         end
         [parM,~] = mapData(Model,data,MRIinputs,Voxels,nW);
         
    end
    
   disp('=============== qMRLab::Fit ======================')
   cprintf('magenta','<< i >> Operation has been started:  %s \n',Model.ModelName);
   cprintf('blue','<< :: >> Parallel:  %d workers \n',nW); 
   cprintf('orange','<< - >> Modal windows have been disabled \n',nW);
   cprintf('red','<< ! >> Temporary result saving has not been implemented in parallel mode yet. \n',nW); 
   
    tStart = tic;
    parfor_progress(nW);
    %p = Par(nW);
    parfor itPar = 1:nW
    %Par.tic;
    parM(itPar).tsaved = 0;
    for ii = 1:length(parM(itPar).NativeIdx)
        
        % Get current voxel data
        Mi = struct();
        for iii = 1:length(MRIinputs)
            Mi.(MRIinputs{iii}) = parM(itPar).(MRIinputs{iii})(ii,:)';
        end
        % Fit data
        try
            parM(itPar).tempFit = Model.fit(Mi);
            parM(itPar).fitFailed = false;
        catch err
            [xii,yii,zii] = ind2sub([x y z],parM(itPar).NativeIdx(ii));
            %fprintf(2, 'Error in voxel [%d,%d,%d]: %s\n',xii,yii,zii,err.message);
            if parM(itPar).fitFailedCounter < 10
              % It is important that errmsg is assigned here but not passed in-line.  
              errmsg = err.message;  
              cprintf('magenta','Solution not found for the voxel [%d,%d,%d]: %s \n',xii,yii,zii,errmsg);
            elseif parM(itPar).fitFailedCounter == 11
              cprintf('blue','%s','Errorenous fit warnings will be silenced for this process.');
              if isMask
                  cprintf('orange','%s','Please condiser providing a binary mask to accelerate fitting.');
              else
                  cprintf('orange','%s','The provided mask probably contains some background voxels.'); 
              end
            end
            
            parM(itPar).fitFailed = true;
            parM(itPar).fitFailedCounter = parM(itPar).fitFailedCounter + 1;
        end
        
        % The variable tempFit won't be declared until the
        % first successful fit. Therefore it is important that
        % we check it. Otherwise, if a fit starts with errorenous voxels,
        % the execution is interrupted.
        if isfield(parM(itPar),'tempFit') 
                
            if isempty(parM(itPar).tempFit);  parM(itPar).Fit=[]; error('Nope'); end
                
            if ~parM(itPar).firstHit
                % Initialize outputs fields
                % This happens only once.
                parM(itPar).fields =  fieldnames(parM(itPar).tempFit)';
                
                if ~isfield(parM(itPar),'Fit')
                for ff = 1:length(parM(itPar).fields)
                    cur_field = parM(itPar).fields{ff};
                    % Initialize only when it does not exist.    
                    % N x 4 for x,y,z and fit value
                    parM(itPar).Fit.(cur_field) = nan(length(parM(itPar).NativeIdx),4);
                end
                end
                parM(itPar).Fit.fields = parM(itPar).fields;
                %parM(itPar).Fit.computed = zeros(length(parM(itPar).NativeIdx),3);
                % Ensure that initialization happens only once when the first
                % solution exists.
                parM(itPar).firstHit = true;    
            end
        end

        % Assign current voxel fitted values
        if ~parM(itPar).fitFailed
            
            for ff = 1:length(parM(itPar).fields)
                cur_field = parM(itPar).fields{ff};
                [xii,yii,zii] = ind2sub([x,y,z],parM(itPar).NativeIdx(ii));
                % Less memory footprint
                parM(itPar).Fit.(cur_field)(ii,:) = [xii,yii,zii,parM(itPar).tempFit.(cur_field)];
            end 
           
        else
           
           % Hits here when fit failed. Exclusive err case
           % For now, substitute fields with xnames, because tempFit does
           % not exist yet. They may be interchangeable, but if they are
           % not some models and there is an unexpected behaviour, this is
           % a good place to start with debugging.
           
           % If first hit did not happen but the flow made its way 
           % here, means that we need to initialize the
           % Fit.(cur_field) matrices here.
           
           if ~isfield(parM(itPar),'Fit')
           for ff = 1:length(Model.xnames)
               cur_field = Model.xnames{ff};
               % Initialized from failed fit. 
               parM(itPar).Fit.(cur_field) = nan(length(parM(itPar).NativeIdx),4); 
           end
           end
                
           for ff = 1:length(Model.xnames)
                cur_field = Model.xnames{ff};
                [xii,yii,zii] = ind2sub([x,y,z],parM(itPar).NativeIdx(ii));
                parM(itPar).Fit.(cur_field)(ii,:) = [xii,yii,zii,NaN];
           end 
            
        end
        
        %  save temp file every 5min
        telapsed = toc(tStart);
        if (mod(floor(telapsed/60),5) == 0 && (telapsed-parM(itPar).tsaved)/60>5)
            if ~exist(tmpFolderName, 'dir')
               mkdir(tmpFolderName);
            end
            parM(itPar).tsaved = telapsed; 
            % save function cannot be called from parfor directly. 
            parSaveTemp(parM(itPar).Fit,tmpFolderName,itPar);
            parM(itPar).tsaved = telapsed;
        end
        
        
    end
    parfor_progress;
    %p(itPar) = Par.toc;
    end % Parallelize
    parfor_progress(0);
    toc(tStart);
    %stop(p);
    %figure(); plot(p);

    cprintf('magenta','<< * >> Operation has been completed:  %s \n',Model.ModelName);
    cprintf('blue','<< i >> FitResults will be saved to your %s \n','working directory:');
    cprintf('blue','      - If specified in the GUI, to the %s \n','Path Data.');
    cprintf('blue','      - Otherwise at %s \n',pwd);
    disp('==================================================')
    
    %reduceData
else % process entire volume
    
   
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

foundFields = true;
it = 1;
% To be on the safe side in case 
while foundFields
    
    if isfield(parM(it),'fields')
        cur_fields = parM(it).fields;
        foundFields = false;
    end
    
    if it == length(parM)
        foundFields = false;
    end
    
    it = it + 1;
end

Fit.fields = cur_fields;

for ii = 1:length(cur_fields)
Fit.(cur_fields{ii}) = zeros(x,y,z);
end

% If there is already processed data, write them in 
if exist('autoSavedDir','var')
    Fit = patchData(Fit,autoSavedDir,x,y,z);
end


if z ==1 
for ii = 1:length(cur_fields)
    cur_field = cur_fields{ii};
    for jj = 1:length(parM)
        cur_fit  = parM(jj).Fit;
        curN =  length(parM(jj).NativeIdx);
        for kk = 1:curN
         x_i = cur_fit.(cur_field)(kk,1);
         y_j = cur_fit.(cur_field)(kk,2);
         Fit.(cur_field)(x_i,y_j) = cur_fit.(cur_field)(kk,4);
        end
    end
end
else % Means 3D
for ii = 1:length(cur_fields)
    cur_field = cur_fields{ii};
    for jj = 1:length(parM)
         xx = parM(jj).Fit.(cur_field)(:,1);
         yy = parM(jj).Fit.(cur_field)(:,2);
         zz = parM(jj).Fit.(cur_field)(:,2);
         idxs = sub2ind([x,y,z],xx,yy,zz);
         Fit.(cur_field)(idxs) = parM(jj).Fit.(cur_field)(:,4);
    end
end   
end
end % Voxelwise parse

if exist(fullfile('.','FitTempResults.mat'),'file')
    delete FitTempResults.mat
end
end

function [parM,splits] = mapData(Model,data,MRIinputs,Voxels,nW)
% Takes (reduced if masked) data struct and returns and struct array 
% to be processed by eack worker.
% data: Struct (if masked only at mask ==1)
% MRIInputs: Field from the model
% Voxels: Native linearized indices of Voxels
% nW: Number of workers to split data into

        parM = struct();

        
        splits = splitIdx(length(Voxels),nW);
        
        for iii = 1:length(MRIinputs)
            for jjj = 1:length(splits)
            parM(jjj).(MRIinputs{iii}) = data.(MRIinputs{iii})(splits(jjj).from:splits(jjj).to,:);
            parM(jjj).NativeIdx = Voxels(splits(jjj).from:splits(jjj).to);
            parM(jjj).fitFailedCounter = 0;
            parM(jjj).firstHit = false;
            parM(jjj).Model = Model;
            end
            if isfield(data,'hdr'), parM(jjj).hdr = data.hdr; end
        end
        
        
        
end


function ss = splitIdx(x,n)
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

ss = struct();
prevmax = 0;
for ii=1:n
    if ii==1
    ss(ii).from = 1;
    ss(ii).to = spidx(ii);
    prevmax = spidx(ii);
    elseif ii==n
    ss(ii).from = x-spidx(ii)+1;
    ss(ii).to   = x;
    else
    ss(ii).from = prevmax + 1;
    ss(ii).to   = prevmax + spidx(ii);
    prevmax = ss(ii).to;
    end
    
end

end

function parSaveTemp(payload,folder,worker)

save([folder filesep 'ParFitTempResults_worker-' num2str(worker) '.mat'], '-struct','payload');

end

function Voxels = rmAutoSavedIndexes(autoSavedDir,Voxels,x,y,z)

fulLen = length(Voxels);

files = dir(fullfile(autoSavedDir,'*.mat'));

those = [];
for ii=1:length(files)
this = load([autoSavedDir filesep files(ii).name]);
% Get native indexes only
this = this.(this.fields{1})(:,1:3);
% Get rid of NaN (unprocessed) parts
that = this(all(~isnan(this),2),:);
% Linearized indexes of that are to be removed from Voxels 
% Collect all of them
rmLin = sub2ind([x,y,z],that(:,1),that(:,2),that(:,3));
those = [those;rmLin];
end

Voxels(intersect(Voxels,those)) = [];

remains = ceil(100*(length(Voxels)/fulLen));
cprintf('blue','%d%s of the data is already processed. Now processing the remaining %d%s... ',100-remains,'%',remains,'%');
end

function Fit = patchData(Fit,autoSavedDir,x,y,z)
files = dir(fullfile(autoSavedDir,'*.mat'));
for ii=1:length(files)
    thisf = load([autoSavedDir filesep files(ii).name]);
    
    for jj=1:length(thisf.fields)
        cur_field = thisf.fields{jj};
        that = thisf.(cur_field);
        that = that(all(~isnan(that),2),:);
        if z==1
            xx = that(:,1);
            yy = that(:,2);
            val = that(:,4);
            idxs = sub2ind([x,y],xx,yy);
            Fit.(cur_field)(idxs) = val;
        else
            xx = that(:,1);
            yy = that(:,2);
            zz = that(:,3);
            val = that(:,4);
            idxs = sub2ind([x,y,z],xx,yy,zz);
            Fit.(cur_field)(idxs) = val;
        end
    end
end
end