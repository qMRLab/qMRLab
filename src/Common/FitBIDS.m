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

    data = getData(niiList,suffix,mapping,modelIdx);
    if ~isempty(p.Results.mask); data.Mask = double(load_nii_data(p.Results.mask)); end
    if ~isempty(p.Results.b1map); data.B1map = double(load_nii_data(p.Results.b1map)); end

    Model = getModel(jsonList,suffix,mapping,modelIdx);
    
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

function data = getData(niiList,suffix,mapping,modelIdx)

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

    end

end

function Model = getModel(jsonList,suffix,mapping,modelIdx)
    
    eval(['Model=' mapping.(suffix){modelIdx}.modelName ';']);
    
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
                    curParam = mapping.(suffix){modelIdx}.protocol.(prots{ii}).(params{jj})
                    Model.Prot.(prots{ii}).Mat = curJson.(curParam);
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