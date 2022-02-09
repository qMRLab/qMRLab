function FitBIDS(niiList,varargin)


    % An easy pattern to fetch all nii.gz files from a dir.
    % BUT this function should expect a selected list of Nii files. 
    % aa = {dir(fullfile(pwd,'*.nii.gz')).name}

    mapping = json2struct('BIDS_to_qmrlab_input_mappings.json');

    setenv('ISBIDS','1');

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
    addParameter(p,'mask',[],validNii);
    addParameter(p,'b1map',[],validNii);
    addParameter(p,'reserveAcq',false,@islogical);
    addParameter(p,'type',[],@ischar);
    addParameter(p,'order',[],@isnumeric);
    addParameter(p,'dimension',[],@ischar);
    addParameter(p,'size',[],@ismatrix);
    addParameter(p,'qmrlab_path',[],@ischar);
    addParameter(p,'sid',[],@ischar);
    addParameter(p,'nextflow',false,@logical);
    addParameter(p,'containerType','',@ischar);
    addParameter(p,'containerTag','',@ischar);
    addParameter(p,'description','Using qMRLab.',@ischar);
    addParameter(p,'datasetDOI',[],@ischar);
    addParameter(p,'datasetURL',[],@ischar);
    addParameter(p,'datasetVersion',[],@ischar);
    addParameter(p, 'targetDir',[],validDir);
    addParameter(p, 'saveMat',false,@islogical);
    addParameter(p, 'selectedModel',[],@ischar);
    
    parse(p,niiList,varargin{:});
    
    if p.Results.nextflow
        setenv('ISNEXTFLOW','1');
    else
        setenv('ISNEXTFLOW','');
    end
    
    targetDir = p.Results.targetDir;
    saveMat = p.Results.saveMat;
    selectedModel = p.Results.selectedModel;

    if isempty(targetDir)
        targetDir = [pwd filesep 'derivatives_' datestr(now,'yyyy-mm-dd_HH-MM-SS')];
        mkdir(targetDir);
    end

    % At this point we have matching niiList and jsonList and the grouping suffix.
    suffix = cell2mat(suffixList{1});

    modelIdx = initCheck(suffix,mapping,selectedModel);

    [data, fieldJsonMap] = getData(niiList,suffix,mapping,modelIdx,jsonList);
    if ~isempty(p.Results.mask); data.Mask = double(load_nii_data(p.Results.mask)); end
    if ~isempty(p.Results.b1map); data.B1map = double(load_nii_data(p.Results.b1map)); end

    Model = getModel(jsonList,suffix,mapping,modelIdx,fieldJsonMap);
    
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
    addDescription.GeneratedBy.Container.Type = p.Results.containerType;
    if ~strcmp(p.Results.containerTag,'null'); addDescription.GeneratedBy.Container.Tag = p.Results.containerTag; end
    if isempty(p.Results.description)
        addDescription.GeneratedBy.Description = 'qMRLab FitBIDS';
    else
        addDescription.GeneratedBy.Description = p.Results.description;
    end
    if ~isempty(p.Results.datasetDOI); addDescription.SourceDatasets.DOI = p.Results.datasetDOI; end
    if ~isempty(p.Results.datasetURL); addDescription.SourceDatasets.URL = p.Results.datasetURL; end
    if ~isempty(p.Results.datasetVersion); addDescription.SourceDatasets.Version = p.Results.datasetVersion; end
    
    SID = p.Results.sid;
    reserveAcq = p.Results.reserveAcq;

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

    % Important do not remove
    setenv('ISBIDS','');

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