function response = modelRegistry(varargin)

p = inputParser();
addParameter(p,'get','modellist',@ischar);

parse(p,varargin{:});

request = p.Results.get;

register = json2struct([fileparts(which('qMRLab.m')) filesep 'dev' filesep 'qmrlab_model_registry.json']);

switch request 
    
    case 'modellist'
       
        response = fieldnames(register);
    
    otherwise
        
        isAModel = isModel(request,register);
        if isAModel
            response.Registry = register.(request);
            % Get mappings between what user requested and what originally
            % exists in qMRLab for:
            % - Input Data
            % - Input Protocols
            % - Output Data 
            response.Mappings = getUnitBIDSMap(register,request);
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

function out = getUnitBIDSMap(register,model)
unitmaps = json2struct([fileparts(which('qMRLab.m')) filesep 'dev' filesep 'xnames_units_BIDS_mappings.json']);
unitDefs = json2struct([fileparts(which('qMRLab.m')) filesep 'dev' filesep 'units.json']);
fields = fieldnames(unitmaps);
lut = [];
for ii=1:length(fields)
    parent = cellstr(repmat(fields{ii},[length(unitmaps.(fields{ii}).xnames) 1]));
    xnames = cellstr(unitmaps.(fields{ii}).xnames)';
    suffix = cellstr(unitmaps.(fields{ii}).suffixBIDS)';
    isBIDS = cell2mat(unitmaps.(fields{ii}).isOfficialBIDS)';
    folderBIDS = cellstr(unitmaps.(fields{ii}).folderBIDS)';
    cur_lut = table(parent,xnames,suffix,isBIDS,folderBIDS,'VariableNames',{'Family','xname','suffixBIDS','isOfficialBIDS','folderBIDS'});
    lut = [lut;cur_lut];
end

% This one includes both optional and non-optional (xnames) outputs.
[~,idxs2] = ismember(fieldnames(register.(model).Outputs),lut.xname);

% This is a struct array. One struct per xname
    % family Namespace of the output type (Time, Ratio ... etc)
    % xname (Output name) 
    % suffixBIDS 
    % isBIDS
    % folderBIDS
    % usrRequestedUnit
    % originalCodeUnit
pre_out = table2struct(lut(idxs2,:));

% User settings
usr = getUserPreferences();

for ii=1:length(pre_out)
    
    if ~strcmp(pre_out(ii).Family,'Categorical') && ~strcmp(pre_out(ii).Family,'Arbitrary')
    % No transformation defined for them
    if usr.UnifyOutputMapUnits.Enabled
        
        origUnitName = register.(model).Outputs.(pre_out(ii).xname);
        usrUnitName = usr.UnifyOutputMapUnits.(pre_out(ii).Family);
        pre_out(ii).ScaleFactor = unitDefs.(pre_out(ii).Family).(origUnitName).factor2base/unitDefs.(pre_out(ii).Family).(usrUnitName).factor2base;
        pre_out(ii).ActiveUnit = usrUnitName;
        pre_out(ii).Symbol = unitDefs.(pre_out(ii).Family).(usrUnitName).symbol;
        pre_out(ii).Label = unitDefs.(pre_out(ii).Family).(usrUnitName).label;
        
    else
        pre_out(ii).MapScaleFactor = 1;
        origUnitName = register.(model).Outputs.(pre_out(ii).xname);
        pre_out(ii).ActiveUnit = origUnitName;
        pre_out(ii).Symbol = unitDefs.(pre_out(ii).Family).(origUnitName).symbol;
        pre_out(ii).Label = unitDefs.(pre_out(ii).Family).(origUnitName).label;
    end
    
    else
        
        pre_out(ii).MapScaleFactor = 1;
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



% From struct array to struct of structs with fieldnames = xname 
new_out = struct();
for ii=1:length(pre_out)
    new_out.Output.(pre_out(ii).xname) = pre_out(ii);
end

% INPUT DATA MAPPINGS -----------------------------------------

Model = eval(model);
inputs = Model.MRIinputs;
    
if isfield(register.(model),'InputDataUnits')
    
    fnames = fieldnames(register.(model).InputDataUnits);
    for ii =1:length(fnames)
       new_out.Input.(fnames{ii}) = getInputDataDetails(register.(model).InputDataUnits.(fnames{ii}));
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
        new_out.Input.(inputs{ii}).ScalingFactor = 1;
        new_out.Input.(inputs{ii}).Symbol = '';
        new_out.Input.(inputs{ii}).Label = 'categorical';
    else
        new_out.Input.(inputs{ii}).Family = 'Arbitrary';
        new_out.Input.(inputs{ii}).ActiveUnit = 'arbitrary';
        new_out.Input.(inputs{ii}).ScalingFactor = 1;
        new_out.Input.(inputs{ii}).Symbol = '';
        new_out.Input.(inputs{ii}).Label = 'arbitrary';
    end
end
    


out = new_out;

end



function out = getInputDataDetails(unitName)

out = struct();
unitDefs = json2struct([fileparts(which('qMRLab.m')) filesep 'dev' filesep 'units.json']);
fields = fieldnames(unitDefs);
% Not Louis Litt, but lookup table
lut = [];
for ii=1:length(fields)
    parent = cellstr(repmat(fields{ii},[length(fieldnames(unitDefs.(fields{ii}))) 1]));
    cur_lut = table(parent,fieldnames(unitDefs.(fields{ii})),'VariableNames',{'Family','unit'});
    lut = [lut;cur_lut];
end

[~,idxs2] = ismember(unitName,lut.unit);

out.Family = cell2mat(lut.Family(idxs2));


usr = getUserPreferences();

if usr.ModifyInputMapUnits.Enabled
    out.ActiveUnit = usr.ModifyInputMapUnits.(out.Family);
    out.Symbol = unitDefs.(out.Family).(out.ActiveUnit).symbol;
    out.Label = unitDefs.(out.Family).(out.ActiveUnit).label;
    % Here we are getting the scaling factor that works for qMRLab 
    % during data load. Lets say, user provided % input for a map where qMRLab 
    % accepts decimal by default. A scaling factor of 0.01 is needed. 
    % So here it should be qmrlab/user 
    out.MapScaleFactor = unitDefs.(out.Family).(out.ActiveUnit).factor2base/unitDefs.(out.Family).(unitName).factor2base;
else
    out.ActiveUnit = unitName;
    out.ScaleFactor = 1;
    out.Symbol = unitDefs.(out.Family).(out.ActiveUnit).symbol;
    out.Label = unitDefs.(out.Family).(out.ActiveUnit).label;
end

end