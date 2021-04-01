function response = modelRegistry(varargin)

    p = inputParser();
    addParameter(p,'get','modellist',@ischar);
    addParameter(p,'registryStruct',[],@isstruct);
    addParameter(p,'unitDefsStruct',[],@isstruct);
    addParameter(p,'usrPrefsStruct',[],@isstruct);


    parse(p,varargin{:});

    request = p.Results.get;
    registryStruct = p.Results.registryStruct;
    unitDefsStruct = p.Results.unitDefsStruct;
    usrPrefsStruct = p.Results.usrPrefsStruct;

    % Read configurations
    % If modelRegistry is called within a loop, reading these files over
    % and over again creates an overhead. To avoid this, following
    % variables can be passed as optional args:
    % - register
    % - unitDefs
    % - usr 
    
    if isempty(registryStruct)
        register = json2struct([fileparts(which('qMRLab.m')) filesep 'dev' filesep 'qmrlab_model_registry.json']);
    else
        register = registryStruct;
        clear('registryStruct');
    end
    
    if isempty(unitDefsStruct)
        unitDefs = json2struct([fileparts(which('qMRLab.m')) filesep 'dev' filesep 'units.json']);
    else
        unitDefs = unitDefsStruct;
        clear('unitDefsStruct');
    end
    
    if isempty(usrPrefsStruct)
        usr = getUserPreferences(); % Reads /usr/preferences.json and parses it
    else
        usr = usrPrefsStruct;
        clear('usrPrefsStruct');
    end

    switch request 
        
        case 'modellist'
        
            response = fieldnames(register)';
            [~,idxc] = ismember('CustomExample',response);
            response(idxc) = [];
            
        
        case 'pathonly'
            
            response = fieldnames(register);
            [~,idxc] = ismember('CustomExample',response);
            response(idxc) = [];
            res2 = cell(1,length(response));
            for ii = 1:length(res2)
                res2{1,ii} = register.(response{ii}).ModelPath;
            end
            response = res2;
            
        otherwise
            
            isAModel = isModel(request,register);
            if isAModel
                response.Registry = register.(request);
                % Get mappings between what user requested and what originally
                % exists in qMRLab for:
                % - Input Data
                % - Input Protocols
                % - Output Data 
                response.UnitBIDSMappings = getUnitBIDSMap(register,request,unitDefs,usr);
            else
                response = [];
                cprintf('red','<< ! >> Cannot find %s in the qMRLab model registry. \n',request);
                cprintf('blue','<< i >> If you are a developer adding a new model (%s), please resigter it to the /dev/qmrlab_model_registry.json file. \n',request);
            end
    end

end

function res = isModel(in,register)
    
    res = ismember(in,fieldnames(register));

end

function out = getUnitBIDSMap(register,model,unitDefs,usr)
    
    unitmaps = json2struct([fileparts(which('qMRLab.m')) filesep 'dev' filesep 'qmrlab_output_to_BIDS_mappings.json']);
    fields = fieldnames(unitmaps);
    lut = [];
    for ii=1:length(fields)
        parent = cellstr(repmat(fields{ii},[length(unitmaps.(fields{ii}).outputs) 1]));
        outputs = cellstr(unitmaps.(fields{ii}).outputs)';
        suffix = cellstr(unitmaps.(fields{ii}).suffixBIDS)';
        isBIDS = cell2mat(unitmaps.(fields{ii}).isOfficialBIDS)';
        folderBIDS = cellstr(unitmaps.(fields{ii}).folderBIDS)';
        cur_lut = cell(length(parent),5);
        cur_lut(:,1) = parent;
        cur_lut(:,2) = outputs;
        cur_lut(:,3) = suffix;
        cur_lut(:,4) = cellstr(num2str(double(isBIDS)));
        cur_lut(:,5) = folderBIDS;
        lut = [lut;cur_lut];
    end

    % This one includes both optional and non-optional outputs.
    [~,idxs2] = ismember(fieldnames(register.(model).Outputs),lut(:,2));

    % Partial match at N=4 to look for templates lie SE_TE*
    if any(idxs2==0)
        fnms = fieldnames(register.(model).Outputs);
        notHit = fnms(idxs2==0);
        notHitIdx = find(idxs2==0);
        xnms = lut(:,2);
        for jj=1:length(notHit)
            idxn = cellfun(@(S) strncmp(notHit(jj),S,4), xnms);
            if any(idxn)
                idxs2(notHitIdx(jj)) = find(idxn==1);
            end
        end
    end
    % This is a struct array. One struct per outputName
        % family Namespace of the output type (Time, Ratio ... etc)
        % outputName (Output name) 
        % suffixBIDS 
        % isBIDS
        % folderBIDS
        % usrRequestedUnit
        % originalCodeUnit
    pre_out = cell2struct(lut(idxs2,:),{'Family','outputName','suffixBIDS','isOfficialBIDS','folderBIDS'},2);

    % User settings
    %usr = getUserPreferences(); % fetch from main

    for ii=1:length(pre_out)
        
        if ~strcmp(pre_out(ii).Family,'Categorical') && ~strcmp(pre_out(ii).Family,'Arbitrary')
        % No transformation defined for them
        if usr.UnifyOutputMapUnits.Enabled
            
            origUnitName = register.(model).Outputs.(pre_out(ii).outputName);
            usrUnitName = usr.UnifyOutputMapUnits.(pre_out(ii).Family);
            pre_out(ii).ScaleFactor = unitDefs.(pre_out(ii).Family).(origUnitName).factor2base/unitDefs.(pre_out(ii).Family).(usrUnitName).factor2base;
            pre_out(ii).ActiveUnit = usrUnitName;
            pre_out(ii).Symbol = unitDefs.(pre_out(ii).Family).(usrUnitName).symbol;
            pre_out(ii).Label = unitDefs.(pre_out(ii).Family).(usrUnitName).label;
            
        else
            pre_out(ii).ScaleFactor = 1;
            origUnitName = register.(model).Outputs.(pre_out(ii).outputName);
            pre_out(ii).ActiveUnit = origUnitName;
            pre_out(ii).Symbol = unitDefs.(pre_out(ii).Family).(origUnitName).symbol;
            pre_out(ii).Label = unitDefs.(pre_out(ii).Family).(origUnitName).label;
        end
        
        else
            
            pre_out(ii).ScaleFactor = 1;
            if strcmp(pre_out(ii).Family,'Arbitrary')
                pre_out(ii).ActiveUnit = 'arbitrary'; 
                pre_out(ii).Symbol = '';
                pre_out(ii).Label = 'arbitrary';
            end
            if strcmp(pre_out(ii).Family,'Categorical')
                pre_out(ii).ActiveUnit = 'categorical';
                pre_out(ii).Symbol = '';
                pre_out(ii).Label = 'categorical';
            end
        
        end
    end



    % From struct array to struct of structs with fieldnames = outputName 
    new_out = struct();
    for ii=1:length(pre_out)
        new_out.Output.(pre_out(ii).outputName) = pre_out(ii);
    end

    % INPUT DATA MAPPINGS -----------------------------------------

    % Corresponds to MRInputs. Here, you CANNOT get this list by instantiating an
    % object. Because, there are some scaled operations required (to populate
    % GUI) during construction (endless recursion otherwise). 

    inputs = fieldnames(register.(model).InputDataUnits);
        
    if isfield(register.(model),'InputDataUnits')
        
        fnames = fieldnames(register.(model).InputDataUnits);
        for ii =1:length(fnames)
        new_out.Input.(fnames{ii}) = getInputDataDetails(register.(model).InputDataUnits.(fnames{ii}),unitDefs,usr);
        % So that the fieldname makes more sense 
        new_out.Input.(fnames{ii}).MRIinput = fnames{ii}; 
        [~,curidx] = ismember(fnames{ii},inputs);
        % Drop these from the input list.
        inputs(curidx) = [];
        end
        
        
    end

    % Iterate over remaining MRIinputs property and assign them
    % Scaling factor is always 1 
    % Categorical for masks etc 

    for ii=1:length(inputs)
        new_out.Input.(inputs{ii}).MRIinput = inputs{ii}; 
        if strcmp(inputs{ii},'Mask')
            new_out.Input.(inputs{ii}).Family = 'Categorical';
            new_out.Input.(inputs{ii}).ActiveUnit = 'categorical';
            new_out.Input.(inputs{ii}).ScaleFactor = 1;
            new_out.Input.(inputs{ii}).Symbol = '';
            new_out.Input.(inputs{ii}).Label = 'categorical';
        else
            new_out.Input.(inputs{ii}).Family = 'Arbitrary';
            new_out.Input.(inputs{ii}).ActiveUnit = 'arbitrary';
            new_out.Input.(inputs{ii}).ScaleFactor = 1;
            new_out.Input.(inputs{ii}).Symbol = '';
            new_out.Input.(inputs{ii}).Label = 'arbitrary';
        end
    end
        

    % Protocol MAPPINGS -----------------------------------------

    if isfield(register.(model),'InputProtUnits')

        fnames = fieldnames(register.(model).InputProtUnits);
        for ii =1:length(fnames)
        new_out.Protocol.(fnames{ii}) = getInputProtocolDetails(register.(model).InputProtUnits.(fnames{ii}),unitDefs,usr);

        end

    end


    out = new_out;

end



function out = getInputDataDetails(unitName,unitDefs,usr)
    % unitName is the FIXED input unit required by the implementation. Here, 
    % we don't have the liberty to change it into something user wants.
    % If user provided their input in a different unit, then they'll specify it
    % in the /usr/preferences.json file (ChangeProvidedInputMapUnits). 
    % Scaling is applied to non-arbitrary/non-categorical inputs when
    % required. 

    out = struct();
    fields = fieldnames(unitDefs);

    lut = [];
    for ii=1:length(fields)
        parent = cellstr(repmat(fields{ii},[length(fieldnames(unitDefs.(fields{ii}))) 1]));
        cur_lut = cell(length(parent),2);
        cur_lut(:,1) = parent;
        cur_lut(:,2) = fieldnames(unitDefs.(fields{ii}));
        lut = [lut;cur_lut];
    end

    [~,idxs2] = ismember(unitName,lut(:,2));

    out.Family = cell2mat(lut(idxs2,1));


    % usr = getUserPreferences(); fetch from main to minimize json reads

    % These are required to infer unit family types
    usr.ChangeProvidedInputMapUnits.Arbitrary = "arbitrary";
    usr.ChangeProvidedInputMapUnits.Categorical = "categorical";

    if usr.ChangeProvidedInputMapUnits.Enabled
        % The name of the input unit is always fixed to that defined in the
        % model registry. MapScale explains with which factor was the user
        % input was multiplied to obtain a map compatible with the qMRLab
        % method. For example, user has relative B1+ in percents. Models use
        % B1+ maps in decimal format, so transform. 

        out.ActiveUnit = unitName;
        out.Symbol = unitDefs.(out.Family).(out.ActiveUnit).symbol;
        out.Label = unitDefs.(out.Family).(out.ActiveUnit).label;
        % Here we are getting the scaling factor that works for qMRLab 
        % during data load. Lets say, user provided % input for a map where qMRLab 
        % accepts decimal by default. A scaling factor of 0.01 is needed. 
        % So here it should be qmrlab/user 
        out.ScaleFactor = unitDefs.(out.Family).(usr.ChangeProvidedInputMapUnits.(out.Family)).factor2base/unitDefs.(out.Family).(unitName).factor2base;
    else
        out.ActiveUnit = unitName;
        out.ScaleFactor = 1;
        out.Symbol = unitDefs.(out.Family).(out.ActiveUnit).symbol;
        out.Label = unitDefs.(out.Family).(out.ActiveUnit).label;
    end

end


function out = getInputProtocolDetails(protClass,unitDefs,usr)
    % unitName is the FIXED input unit required by the implementation. Here, 
    % we don't have the liberty to change it into something user wants.
    % If user's would like to provide protocol inputs in a different unit 
    % (e.g. inversion_recovery inputs are in msec), but user would like to pass
    % TI(s) in seconds. 

    out = struct();
    fields = fieldnames(unitDefs);

    lut = [];
    for ii=1:length(fields)
        parent = cellstr(repmat(fields{ii},[length(fieldnames(unitDefs.(fields{ii}))) 1]));
        cur_lut = cell(length(parent),2);
        cur_lut(:,1) = parent;
        cur_lut(:,2) = fieldnames(unitDefs.(fields{ii}));
        lut = [lut;cur_lut];
    end

    protNames = fieldnames(protClass);
    %usr = getUserPreferences(); % fetch from main to minimize json reads
    % These are required to infer unit family types
    usr.ChangeProvidedInputMapUnits.Arbitrary = "arbitrary";
    usr.ChangeProvidedInputMapUnits.Categorical = "categorical";

    for ii=1:length(protNames)
    % Protocol key/value pairs are wrapped in a namespace that we need to
    % iterate over here. 

    [~,idxs2] = ismember(protClass.(protNames{ii}),lut(:,2));
    unitFamilyName = cell2mat(lut(idxs2,1));
    out.(protNames{ii}).Family = unitFamilyName;

    if usr.UnifyInputProtocolUnits.Enabled
        out.(protNames{ii}).ActiveUnit = usr.UnifyInputProtocolUnits.(unitFamilyName);
        out.(protNames{ii}).Symbol = unitDefs.(unitFamilyName).(out.(protNames{ii}).ActiveUnit).symbol;
        out.(protNames{ii}).Label = unitDefs.(unitFamilyName).(out.(protNames{ii}).ActiveUnit).label;
        out.(protNames{ii}).ScaleFactor = unitDefs.(unitFamilyName).(usr.UnifyInputProtocolUnits.(unitFamilyName)).factor2base/unitDefs.(unitFamilyName).(protClass.(protNames{ii})).factor2base;
    else
        % Then the active unit is the original one.
        out.(protNames{ii}).ActiveUnit = protClass.(protNames{ii});
        % Therefore scaling is 1. 
        out.(protNames{ii}).ScaleFactor = 1;
        out.(protNames{ii}).Symbol = unitDefs.(out.(protNames{ii}).Family).(out.(protNames{ii}).ActiveUnit).symbol;
        out.(protNames{ii}).Label = unitDefs.(out.(protNames{ii}).Family).(out.(protNames{ii}).ActiveUnit).label;
    end

    end
end
