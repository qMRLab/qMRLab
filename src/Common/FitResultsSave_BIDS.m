function outPrefix = FitResultsSave_BIDS(FitResults,niiHeader,subID,varargin)


    warning('off', 'MATLAB:MKDIR:DirectoryExists');

    qMRLabDir = fileparts(which('qMRLab.m'));

    % When this function is called, env variable ISBIDS will be set to 1
    % to override user preferences to determine output units. 
    % See more in getUserPreferences.m 

    % ================================= CRITICAL DO NOT REMOVE
    setenv('ISBIDS','1'); 
    % ================================= 

    % Get model registry to access UnitBIDSMappings
    reg = modelRegistry('get',FitResults.Model.ModelName);


    % If qmrlab_output_to_BIDS_mappings.json is updated by the developer to 
    % reflect changes in a new BIDS release, BIDSVersion tag in the sidecar
    % JSON files should capture it. 
    infoBIDS = json2struct(fullfile(qMRLabDir,'dev','bids_specification','qmrlab_BIDS_changelog.json'));

    validNii = @(x) exist(x,'file') && (strcmp(x(end-5:end),'nii.gz') || strcmp(x(end-2:end),'nii'));
    validDir = @(x) exist(x,'dir');
    
    p = inputParser();
    addRequired(p,'FitResults',@isstruct);
    addRequired(p,'niiHeader',validNii);
    addRequired(p,'subID',@ischar);
    addParameter(p,'ses',[],@ischar);
    addParameter(p,'sesFolder',false,@islogical);
    addParameter(p,'acq',[],@ischar);
    addParameter(p,'rec',[],@ischar);
    addParameter(p, 'targetDir',[],validDir);
    addParameter(p, 'injectToJSON',struct(),@isstruct);
    addParameter(p, 'saveDescription',true,@islogical);

    parse(p,FitResults,niiHeader,subID, varargin{:});

    subID = p.Results.subID;
    FitResults = p.Results.FitResults;
    niiHeader = p.Results.niiHeader;
    sesValue = p.Results.ses;
    writeSesFolder = p.Results.sesFolder;
    acqValue = p.Results.acq;
    recValue = p.Results.rec;
    injectJSON = p.Results.injectToJSON;
    saveDescription = p.Results.saveDescription;
    targetDir = p.Results.targetDir;


    % Get dataset_description struct.
    datasetDescription = getDatasetDescription(infoBIDS.version,injectJSON);

    % Here, target dir points to the derivatives folder 
    % If not, create a derivatives folder with timestamp 
    if isempty(targetDir)
        targetDir = [pwd filesep 'derivatives_' datestr(now,'yyyy-mm-dd_HH-MM')];
    end

    % This is the subject directory for the outputs
    subDir = fullfile(targetDir,'qMRLab',['sub-' subID]);

    if isempty(getenv('ISNEXTFLOW')) && ~str2double(getenv('ISNEXTFLOW'))
        % In the derivatives folder, we first create a qMRLab/sub directory.
        if ~exist(subDir, 'dir')
            mkdir(subDir);
        end
    end

    % Save derivatives/qMRLab/dataset_description.json (true by default).
    if saveDescription
        if ~isempty(getenv('ISNEXTFLOW')) && str2double(getenv('ISNEXTFLOW'))
            % This file is saved under derivatives/qMRLab
            % Nextflow signals whether the dataset has session level organization. 
            % If so, saved 3 dirs up, otherwise 2 dir up.
            if writeSesFolder
                savejson([],datasetDescription,fullfile('..','..','..','dataset_description.json'));
            else
                savejson([],datasetDescription,fullfile('..','..','dataset_description.json'));
            end
        else
            % Save defined directory if not nextflow.
            savejson([],datasetDescription,fullfile(targetDir,'qMRLab','dataset_description.json'));
        end
    end

    % injectJSON already has its respective BIDSVersion management
    datasetDescription = rmfield(datasetDescription,'BIDSVersion');

    % Fetch the list of the output fieldnames in FitResults struct
    % We'll loop over them to save files where they belong under the 
    % derivatives/qMRLab/sub- folder 

    outputFields = FitResults.fields;

    % Main loop =============================================]
    for fieldIdx = 1:length(outputFields)

        % Create output type folder. This depends on the model. For example, diffusion models 
        % are saved to dwi, fieldmaps are to fmap and others to anat. These must have been 
        % defined in the model registry schema. 

        curMapping = reg.UnitBIDSMappings.Output.(outputFields{fieldIdx});

        % In case user Fit their data w/o BIDS enabled, but requests 
        % saving outputs in BIDS, check if it calls for scaling. 
        % To test this:
        % - ForAllUnitsUseBIDS false 
        % - UnifyOutput enable and set to a different unit (than that model's original units)
        % - Call FitResultsSave_BIDS to see if the output map is saved in BIDS units.

        usrpreferences = getUserPreferences();

        if ~usrpreferences.ForAllUnitsUseBIDS
            
            usrMapping = FitResults.UnitBIDSMappings.Output.(outputFields{fieldIdx});

            if ~isequal(curMapping.ActiveUnit,usrMapping.ActiveUnit)
                % We need to fetch relative scaling factor.
                relScaling = curMapping.ScaleFactor./usrMapping.ScaleFactor;
                % Scale that field
                FitResults.(outputFields{fieldIdx}) = FitResults.(outputFields{fieldIdx}).*relScaling;
            end

        end

        % IF NEXTFLOW, HAND OVER RESPONSIBILITY TO NF FOR MANAGING DIRECTORY 
        % In this case, it is simply like we are reading and writing files in 
        % the same (current) folder. 
        if ~isempty(getenv('ISNEXTFLOW')) && str2double(getenv('ISNEXTFLOW'))
            % SubID captures all these details in nextflow
            curFileName = getSaveName(subID,[],acqValue,[],curMapping.suffixBIDS);
            % Output them where Nextflow expects
            curOutDir   = pwd; 
        else
            curOutDir = fullfile(subDir,curMapping.folderBIDS);

            if ~exist(curOutDir, 'dir')
                mkdir(curOutDir);
            end

            % If requested, write session folder. This is not required for all the outputs with sessions. 
            % Up to user's choice. BIDS is OK with both options.
            if writeSesFolder
                try
                    curOutDir = fullfile(curOutDir,['ses-' sesValue]);
                    mkdir(curOutDir);
                catch
                    error('Missing session value. Please pass the value such as: FitResultsSave_BIDS(''ses'',''00N'')');
                end
            end
            curFileName = getSaveName(subID,sesValue,acqValue,recValue,curMapping.suffixBIDS);
        end 

        if ~isempty(reg.Registry.Citation)
            injectJSON.EstimationReference =  reg.Registry.Citation;
        end

        % Not all the suffix name in qMRLab are defined in original BIDS. Relevant 
        % information is available in the model registry: isOfficialBIDS. If a suffix is not 
        % official BIDS, we need to redact BIDSVersion in the json. 

        if logical(str2double(curMapping.isOfficialBIDS))
            injectJSON.BIDSVersion = infoBIDS.version;
        else
            injectJSON.BIDSVersion = 'N/A';
        end

        % Add provenance information to the JSON 
        provs  =fieldnames(FitResults.Provenance);
        for ii=1:length(provs)
            injectJSON.(provs{ii}) = FitResults.Provenance.(provs{ii});
        end

       
        % Inject dataset_description to map jsons as well. 
        descriptions  = fieldnames(datasetDescription);
        for ii=1:length(descriptions)
            injectJSON.(descriptions{ii}) = datasetDescription.(descriptions{ii});
        end

        % SAVE NIFTI AND JSON FOR THIS FIELD 
        % For now, pass protocols to this function in wrappers in array form.
        % TODO:
        % When BIDS input mappings are finalized, then we can move that functionality here.

        % Save NIFTI
        save_nii_v2(FitResults.(outputFields{fieldIdx}),fullfile(curOutDir,[curFileName '.nii.gz']),niiHeader,64);

        % Save JSON 
        savejson([],injectJSON,fullfile(curOutDir,[curFileName '.json']));
        
        if nargout==1
            % Return base upon request
            outPrefix  = fullfile(curOutDir,curFileName);
        end
    end

    % ================================= CRITICAL DO NOT REMOVE
    setenv('ISBIDS',''); 
    % =================================

    warning('on', 'MATLAB:MKDIR:DirectoryExists');

end



function fileName = getSaveName(subID,sesValue,acqValue,recValue,suffix)
    % Return BIDS output names based on the values passed for BIDS 
    % entities and the suffix inferred from model registry.

    if ~isempty(sesValue); subID = [subID '_ses-' sesValue]; end
    if ~isempty(acqValue); subID = [subID '_acq-' acqValue]; end
    if ~isempty(recValue); subID = [subID '_rec-' recValue]; end
    if ~isempty(getenv('ISNEXTFLOW')) && str2double(getenv('ISNEXTFLOW'))
        fileName = [subID '_' suffix];
    else
        fileName = ['sub-' subID '_' suffix];
    end

end


function datasetDescription = getDatasetDescription(BIDSVersion, optionalFields)

    % JSON file for dataset_description
    datasetDescription = struct();
    datasetDescription.Name = 'qMRLab Outputs';
    datasetDescription.BIDSVersion = BIDSVersion;
    datasetDescription.DatasetType = 'derivative';
    datasetDescription.GeneratedBy.Name = 'qMRLab';
    datasetDescription.GeneratedBy.Version = qMRLabVer();

    % Update this cell array if dataset_description adds other 
    % optional fields in the future. 
    optionalBIDSFields = [{'GeneratedBy'},{'SourceDatasets'}];

    if ~isempty(fieldnames(optionalFields))
        fnames = fieldnames(optionalFields);
        for ii =1:length(fnames)
            if ismember(fnames{ii},optionalBIDSFields)
                datasetDescription.(fnames{ii}) = optionalFields.(fnames{ii});
            end
        end
    end

end