function FitBIDS(niiList,varargin)
%         __  __ ____  _          _
%    __ _|  \/  |  _ \| |    __ _| |__
%   / _` | |\/| | |_) | |   / _` | '_ \
%  | (_| | |  | |  _ <| |__| (_| | |_) |
%   \__, |_|  |_|_| \_\_____\__,_|_.__/
%      |_|
% -------------------------------------------------------------------------
% void FitBIDS(niiList, varargin)
%
% Takes a list (vector) of BIDS compatible NIFTI files for a single 
% dataset (or participant). This function does not loop over participants
% or different variations (e.g. acq-exp1, acq-exp2) of the data.
%
% Please see dev/BIDS_to_qmrlab_input_mappings.json for supported file 
% collections.
% -------------------------------------------------------------------------
% Required inputs:
%
%     niiList                       A cell array of a BIDS compatible 
%                                   NIFTI file collection (cell array).
%                                   Example:
%                                   {'sub-01_flip-01_VFA.nii.gz',
%                                    'sub-01_flip-02_VFA.nii.gz'}
%
% Output:
%
%     derivatives                   Outputs will be written in files.
%                                   See optional parameters for further info. 
%
% 
% FitBIDS(___,PARAM1, VAL1, PARAM2, VAL2,___)
%
% Optional parameters include:
%
%
%   'TargetDir'                     A target derivatives directory. If provided,
%                                   the BIDS outputs will be written under 
%                                   qMRLab folder following the respective BIDS
%                                   convention of the processed file collection.
%                                   Default: [] (string) 
%
%   'SaveMat'                       Determines whether or not to save FitResults.mat
%                                   and other output maps in *.mat format. If enabled,
%                                   the mat files will be exported in the same directory
%                                   where BIDS outputs are written.
%                                   Default: false (bool)
%                                   
%
%   'SelectedModel'                 If multiple qMRLab models are available for 
%                                   a given file collection (e.g. MESE), this 
%                                   option can be used to select the desired 
%                                   model. If not provided, the default model
%                                   will be used for the respective file collection.
%                                   Example:
%                                          >> FitBIDS(niiList,'SelectedModel','mwf');
%                                   Default: [] (string)
%
%   'FitOptions'                    To fit data using user-defined options. The 
%                                   provided struct MUST match the Model.options 
%                                   property of the respective model. 
%                                   Example: 
%                                           >> my_model = mono_t2;
%                                           >> my_options = my_model.options;
%                                           >> my_options.DropFirstEcho = true;
%                                           >> FitBIDS(niiList,'FitOptions',my_options);
%                                   Default: [] (struct - qMRLab::Model::options)
%
%   'Mask'                          NIFTI formatted binary mask to define 
%                                   foreground voxels. 
%                                   Default: [] (string)
%
%   'B1map'                         BIDS compatible (NIFTI) B1+ map (% relative untis).
%                                   Pass only if B1+ correction is available 
%                                   for the file collection in question.
%                                   Default: [] (string)
%
%   'ReserveAcq'                    If the file collection uses the acq entity,
%                                   setting this option to true is needed to 
%                                   omit the acq- entity from the output names. 
%                                   Default: false (bool)
%
%   'Nextflow'                      Enabling this option changes the I/O behaviour 
%                                   to use qMRLab in qMRFlow.
%                                   Default: false (bool)
%
%   'QmrlabPath'                    For workflow executors to handle cases where 
%                                   qMRLab is not in the path by default.
%                                   Default: [] (string)
%
%   'SID'                           Subject ID to create outputs following workflow 
%                                   executor (external) tags. 
%                                   Default: [] (string)
%
%   'DatasetDOI'                    DOI of the used dataset, appears on 
%                                   the derivatives if provided.
%                                   Default: [] (string)
%
%   'DatasetURL'                    URL of the used dataset, appears on 
%                                   the derivatives if provided.
%                                   Default: [] (string)
%
%   'DatasetVersion'                Version of the used dataset, appears on 
%                                   the derivatives if provided.
%                                   Default: [] (string)
%
%   'ContainerType'                 Appears on the derivatives (json) if 
%                                   provided.
%                                   Default: [] (string)
%
%   'ContainerTag'                  Appears on the derivatives (json) if 
%                                   provided.
%                                   Default: [] (string)
%
%   'Description'                   Custom description to appear on the
%                                   derivatives provenance. 
%                                   Default: [] (string)
%
% Functionality:
%
%     Process BIDS formatted qMRI data for a <<single participant>>. If the
%     provided files are a valid BIDS file collection and the respective model
%     is implemented in qMRLab, necessary settings will be handled automatically
%     to fit data and to save BIDS-conformant outputs.
%
% -------------------------------------------------------------------------
% Written by: Agah Karakuzu
% -------------------------------------------------------------------------
% References
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F.,
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab:
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343
% -------------------------------------------------------------------------


    % An easy pattern to fetch all nii.gz files from a dir.
    % BUT this function should expect a selected list of Nii files. 
    % aa = {dir(fullfile(pwd,'*.nii.gz')).name}

    try 
    % The whole thing is written in a try-catch block to ensure that 
    % ISBIDS is set to null on error. Otherwise the env variable will persists
    % and may lead to unexpected behaviour.

    mapping = json2struct('BIDS_to_qmrlab_input_mappings.json');

    % ================================= CRITICAL DO NOT REMOVE
    setenv('ISBIDS','1');
    % =================================

    p = inputParser();

    %Input parameters conditions
    validNii = @(x) exist(x,'file') && (strcmp(x(end-5:end),'nii.gz') || strcmp(x(end-2:end),'nii'));
    validJson = @(x) exist(x,'file') && strcmp(x(end-3:end),'json');
    validCellArray = @(x) isvector(x) && iscell(x);
    validDir = @(x) exist(x,'dir');
    addRequired(p,'niiList',validCellArray);
    jsonList = cellfun(@(x) [x(1:strfind(x,'.nii')) 'json'] ,niiList,'UniformOutput',false);
    jsonList = cellfun(@(x) dropPart(x) ,jsonList,'UniformOutput',false);

    for ii=1:length(niiList)
        assert(validNii(niiList{ii}),[niiList{ii} ' is not valid NiFTI or does not exist.']);
        assert(validJson(jsonList{ii}),[jsonList{ii} ' is not valid NiFTI or does not exist.']);
    end
    
    suffixList = cellfun(@(x) cellstr(regexp(x,'(?!.*_).*?(?=.nii)','match')) ,niiList,'UniformOutput',false);
    assert(length(unique([suffixList{:}]))==1,['niiList should contain only one grouping suffix: ' cell2mat(unique([suffixList{:}]))]);

    %Add OPTIONAL Parameteres
    addParameter(p, 'TargetDir',[],validDir);
    addParameter(p, 'FitOptions',[],@isstruct);
    addParameter(p, 'SaveMat',false,@islogical);
    addParameter(p, 'SelectedModel',[],@ischar);
    addParameter(p,'Mask',[],validNii);
    addParameter(p,'B1map',[],validNii);
    addParameter(p,'ReserveAcq',false,@islogical);
    addParameter(p,'Nextflow',false,@islogical);
    addParameter(p,'QmrlabPath',[],@ischar);
    addParameter(p,'SID',[],@ischar);
    addParameter(p,'DatasetDOI',[],@ischar);
    addParameter(p,'DatasetURL',[],@ischar);
    addParameter(p,'DatasetVersion',[],@ischar);
    addParameter(p,'ContainerType','',@ischar);
    addParameter(p,'ContainerTag','',@ischar);
    addParameter(p,'Description','Using qMRLab.',@ischar);


    
    parse(p,niiList,varargin{:});
    
    if p.Results.Nextflow
        setenv('ISNEXTFLOW','1');
    else
        setenv('ISNEXTFLOW','');
    end

    if ~isempty(p.Results.QmrlabPath); qMRdir = p.Results.QmrlabPath; end
    
    try
        disp('=============================');
        qMRLabVer;
    catch
        warning('Cant find qMRLab. Adding qMRLab_DIR to the path: ');
        if ~strcmp(qMRdir,'null')
            qmr_init(qMRdir);
        else
            error('Please set qMRLab_DIR parameter in the nextflow.config file.');
        end
        qMRLabVer;
    end
    
    targetDir = p.Results.TargetDir;
    saveMat = p.Results.SaveMat;
    selectedModel = p.Results.SelectedModel;
    fitOptions = p.Results.FitOptions;

    if isempty(targetDir)
        targetDir = [pwd filesep 'derivatives_' datestr(now,'yyyy-mm-dd_HH-MM-SS')];
        mkdir(targetDir);
    end

    % At this point we have matching niiList and jsonList and the grouping suffix.
    suffix = cell2mat(suffixList{1});

    modelIdx = initCheck(suffix,mapping,selectedModel);

    [data, fieldJsonMap] = getData(niiList,suffix,mapping,modelIdx,jsonList);
    if ~isempty(p.Results.Mask); data.Mask = double(load_nii_data(p.Results.Mask)); end
    if ~isempty(p.Results.B1map); data.B1map = double(load_nii_data(p.Results.B1map)); end

    Model = getModel(jsonList,suffix,mapping,modelIdx,fieldJsonMap);

    if ~isempty(fitOptions)
        Model.options = fitOptions;
    end
    
    if ~Model.voxelwise
        FitResults = FitData(data,Model,0);
    else
        usr = getUserPreferences();
        if usr.FitParallelWheneverPossible
            FitResults = ParFitData(data,Model);
        else
            FitResults = FitData(data,Model,0);
        end
    end

    addDescription = struct();
    addDescription.BasedOn = niiList;
    addDescription.Protocol = Model.Prot;
    addDescription.Options  = Model.options;
    addDescription.GeneratedBy.Container.Type = p.Results.ContainerType;
    if ~strcmp(p.Results.ContainerTag,'null'); addDescription.GeneratedBy.Container.Tag = p.Results.ContainerTag; end
    if isempty(p.Results.Description)
        addDescription.GeneratedBy.Description = 'qMRLab FitBIDS';
    else
        addDescription.GeneratedBy.Description = p.Results.Description;
    end
    if ~isempty(p.Results.DatasetDOI); addDescription.SourceDatasets.DOI = p.Results.DatasetDOI; end
    if ~isempty(p.Results.DatasetURL); addDescription.SourceDatasets.URL = p.Results.DatasetURL; end
    if ~isempty(p.Results.DatasetVersion); addDescription.SourceDatasets.Version = p.Results.DatasetVersion; end
    
    SID = p.Results.SID;
    reserveAcq = p.Results.ReserveAcq;

    % Infer
    if isempty(SID)

        details = getDetails(niiList{1});
        SID = details.sub;
        if ~isempty(details.ses)
            outPrefix = FitResultsSave_BIDS(FitResults,niiList{1},SID,'injectToJSON',addDescription,'sesFolder',true,'ses',details.ses,'targetDir',targetDir);
            if ~isempty(details.acq) && ~reserveAcq
                outPrefix = FitResultsSave_BIDS(FitResults,niiList{1},SID,'injectToJSON',addDescription,'sesFolder',true,'ses',details.ses,'acq',details.acq,'targetDir',targetDir);
            end
        else
            if ~isempty(details.acq) && ~reserveAcq
                outPrefix = FitResultsSave_BIDS(FitResults,niiList{1},SID,'injectToJSON',addDescription,'acq',details.acq,'targetDir',targetDir);
            end

        end
        
        % Outprefix is not as clean as its with nextflow 
        loc = strfind(outPrefix,filesep);
        outPrefix = outPrefix(1:max(loc));
        Model.saveObj([outPrefix suffix '.qmrlab.mat']);
        if saveMat
            FitResultsSave_mat(FitResults,outPrefix);
        end
        
    else % Nextflow case

    end

    % ================================= CRITICAL DO NOT REMOVE
    setenv('ISBIDS','');
    % ================================= 

    catch ME

    % ================================= NULL ENV VAR ON ERROR
    setenv('ISBIDS','');
    setenv('ISNEXTFLOW','');
    % =================================
    cprintf('red','ERROR ID: %s',ME.identifier);
    fprintf(1,'\n ERROR MESSAGE:\n %s \n',ME.message);

    end

end

function output = dropPart(input)
    if strfind(input,'_part-mag')
        input(strfind(input,'_part-mag'):strfind(input,'_part-mag')+length('_part-mag')-1) = [];
    elseif strfind(input,'_part-phase')
        input(strfind(input,'_part-phase'):strfind(input,'_part-phase')+length('_part-phase')-1) = [];
    end
    output = input;
end

function modelIdx = initCheck(suffix,mapping,selectedModel);

    if length(mapping.(suffix)) == 1
    
        modelIdx =1;
    
    else
    
        if isempty(selectedModel)
                cprintf('magenta','Multiple qMRLab models are available for the suffix %s',suffix);
                cprintf('blue','Selecting the default model %s ', mapping.(suffix){1}.modelName);
                cprintf('magenta','Pass `modelSelection` optional variable %s %s', 'to select other models for', suffix );
                modelIdx = 1;
        else

            idxs = [];
            for rr = 1:length(mapping.(suffix))
                idxs = [idxs strcmp(selectedModel,mapping.(suffix){rr}.modelName)];
            end

            modelIdx = find(idxs==1);

            if isempty(modelIdx)
                error(['Requested model ' selectedModel ' is not available for the suffix ' suffix]);
            end
        end
    
    end

end

function [data, fieldJsonMap] = getData(niiList,suffix,mapping,modelIdx,jsonList)

    if mapping.(suffix){modelIdx}.mergeData
    
        sample = load_nii_data(niiList{1});
        sz = size(sample);

        if ndims(sample)==2
                DATA = zeros(sz(1),sz(2),1,length(niiList));
        elseif ndims(sample)==3
                DATA = zeros(sz(1),sz(2),sz(3),length(niiList));
        else
            error('Data is not a volume or a slice.');
        end

        for ii=1:length(niiList)
            DATA(:,:,:,ii) =  double(load_nii_data(niiList{ii}));
        end

        data = struct();

        data.(mapping.(suffix){modelIdx}.dataField) = DATA;

        fieldJsonMap = [];
    
    else
    % In this case the data needs to be loaded in different fields 
    % and the mapping is defined by entities and the respective 
    % metadata calues. 
        
        data = struct();
        dataFields = mapping.(suffix){modelIdx}.dataField;
        entity = mapping.(suffix){modelIdx}.entity;
        fieldFileMap  = cell(length(dataFields),2);
        fieldFileMap(:) = {'empty'};

        for ii = 1:length(entity)

            fieldFileMap(ii,1) = dataFields(ii); % There's 1/1 mapping between entity and data field names

            if strfind(entity{ii},'-')
                % Convention: Look for exact match if the entity given for a dataField contains -.    
                % Use partial match to find the respective file 
                fieldFileMap(ii,2) = niiList(~cellfun(@isempty,strfind(niiList,entity{ii})));
            
            elseif strfind(entity{ii},':')
                % Conditional match based on the metadata value associated with the entity. 
                tmp = strsplit(entity{ii},':');
                metaKey = getEntityMetaKey(tmp{1});
                curCond = tmp{2};

                % Now we'll sort all the file names according to the value of the metaKey
                tmp = cell(length(niiList),2);
                for jj = 1:length(niiList)
                    curJson = json2struct(jsonList{jj});
                    tmp(jj,1) = niiList(jj);
                    tmp(jj,2) = {curJson.(metaKey)};
                end
                % Then we'll exclude non-empty fieldFileMap's 2nd column to avoid overlap
                % with already dealt with files
                rmIdx = ismember(tmp(:,1),fieldFileMap(:,2));
                tmp(rmIdx,:) = [];

                % Sort 
                tmpSorted = sortrows(tmp,2,'ascend');

                if strcmp(curCond,'low')
                    fieldFileMap(ii,2) = tmpSorted(1,1);
                elseif strcmp(curCond,'high')
                    fieldFileMap(ii,2) = tmpSorted(end,1);
                end
            end
        end

        fieldJsonMap  = fieldFileMap;
        % Now read data into the right fields. 
        for ii = 1:length(fieldFileMap)

            data.(fieldFileMap{ii,1}) = double(load_nii_data(fieldFileMap{ii,2}));
            x = fieldFileMap{ii,2};
            fieldJsonMap(ii,2) =  {[x(1:strfind(x,'.nii')) 'json']};
        end

    end

end

function Model = getModel(jsonList,suffix,mapping,modelIdx,fieldJsonMap)
    
    eval(['Model=' mapping.(suffix){modelIdx}.modelName ';']);
    
 if ~isempty(mapping.(suffix){modelIdx}.protocol)
    if mapping.(suffix){modelIdx}.mergeData

        prots = fieldnames(mapping.(suffix){modelIdx}.protocol);

        for ii = 1:length(prots)

            if isfield(mapping.(suffix){modelIdx}.protocol.(prots{ii}),'Matrix')
            % This one is assumed to be varying across images
                params = mapping.(suffix){modelIdx}.protocol.(prots{ii}).Matrix;
                Mat = zeros(length(jsonList),length(params));

                for jj = 1:length(jsonList)
                    curJson = json2struct(jsonList{jj});
                    for kk = 1:length(params)
                    Mat(jj,kk) = curJson.(params{kk});
                    end
                end

                Model.Prot.(prots{ii}).Mat = Mat;
            else
                % This one is assumed to be constant across images
                curJson = json2struct(jsonList{1});
                params = fieldnames(mapping.(suffix){modelIdx}.protocol.(prots{ii}));
                Model.Prot.(prots{ii}).Mat = zeros(1,length(params));
                for jj=1:length(params)
                    curParam = mapping.(suffix){modelIdx}.protocol.(prots{ii}).(params{jj});
                    Model.Prot.(prots{ii}).Mat = curJson.(curParam{1});
                end
            end
        
        end
    
    else

        if ~isempty(fieldJsonMap)
            % Means that getData returned the mapping between json files and params. 
            

            prots = fieldnames(mapping.(suffix){modelIdx}.protocol);

            for ii = 1:length(prots)

                [matched,idx] = ismember(prots{ii},cellstr(fieldJsonMap(:,1)));
                
                % If the fieldnames of the data and the prot are matching
                % read the metadata.
                if matched
                    curFile  = fieldJsonMap{idx,2};
                    curJson = json2struct(curFile);
                end

                if isfield(mapping.(suffix){modelIdx}.protocol.(prots{ii}),'Matrix')

                    params = mapping.(suffix){modelIdx}.protocol.(prots{ii}).Matrix;

                    % In this case we have only one json file, with multiple params.
                    Mat = zeros(1,length(params));

                    for jj = 1:length(params)
                        Mat(1,jj) = curJson.(params{jj});
                    end

                    try 
                        % First assumes that the fieldnames of the data and protocol are matching. 
                        Model.Prot.(prots{ii}).Mat = Mat;
                    catch
                        warning('TODO: Not handled for the matrix case yet.');
                    end

                else
                % If not matrix, key value of each entry will be mapped to the given value

                    params = fieldnames(mapping.(suffix){modelIdx}.protocol.(prots{ii}));
                    Model.Prot.(prots{ii}).Mat = zeros(1,length(params));
                    for jj=1:length(params)
                        curParam = mapping.(suffix){modelIdx}.protocol.(prots{ii}).(params{jj});
                        if length(curParam) == 1
                            % Fieldnames of the data and protocol are matching.
                            Model.Prot.(prots{ii}).Mat(1,jj) = curJson.(curParam{1});
                        
                        elseif length(curParam) == 2
                        
                            % This means that we have a tricky case. We need to populate the 
                            % field by reading the correct json file.
                            % Format: [MetadataField,DataFieldName]
                            [~,idx2] = ismember(curParam{2},cellstr(fieldJsonMap(:,1)));
                            tmpFile  = fieldJsonMap{idx2,2};
                            tmpJson = json2struct(tmpFile);
                            Model.Prot.(prots{ii}).Mat(1,jj) = tmpJson.(curParam{1});
                        
                        end
                    end

                end

            end
        end

    end
 end
end

function out = getDetails(fname)
    out = struct();
    out.sub = regexp(fname,'(?<=sub-).*?(?=_)','match');
    if ~isempty(out.sub); out.sub  = out.sub{end}; end
    out.ses = regexp(fname,'(?<=ses-).*?(?=_)','match');
    if ~isempty(out.ses); out.ses  = out.ses{end}; end
    out.acq = regexp(fname,'(?<=acq-).*?(?=_)','match');
    if ~isempty(out.acq); out.acq  = out.acq{end}; end
end

function out = getEntityMetaKey(entity)
    switch entity
    case "flip"
        out = "FlipAngle";
    case "inv"
        out = "InversionTime";
    case "echo"
        out = "EchoTime";
    case "mt"
        out = "MTState";
    end
end