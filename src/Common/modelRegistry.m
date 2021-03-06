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
            % Get details
            response.KeyMaps = getUnitBIDSMap(register,request);

            
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
    cur_lut = table(parent,xnames,suffix,isBIDS,folderBIDS,'VariableNames',{'family','xname','suffixBIDS','isOfficialBIDS','folderBIDS'});
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
    
    if ~strcmp(pre_out(ii).family,'Categorical') && ~strcmp(pre_out(ii).family,'Arbitrary')
    % No transformation defined for them
    if usr.UnifyOutputMapUnits.Enabled
        
        origUnitName = register.(model).Outputs.(pre_out(ii).xname);
        usrUnitName = usr.UnifyOutputMapUnits.(pre_out(ii).family);
        pre_out(ii).MapScaleFactor = unitDefs.(pre_out(ii).family).(origUnitName).factor2base/unitDefs.(pre_out(ii).family).(usrUnitName).factor2base;
        pre_out(ii).OutputUnit = usrUnitName;
        
    else
        pre_out(ii).MapScaleFactor = 1;
        origUnitName = register.(model).Outputs.(pre_out(ii).xname);
        pre_out(ii).OutputUnit = origUnitName;
    end
    
    else
        
        pre_out(ii).MapScaleFactor = 1;
        if strcmp(pre_out(ii).family,'Arbitrary'); pre_out(ii).OutputUnit = 'arbitrary'; end
        if strcmp(pre_out(ii).family,'Categorical'); pre_out(ii).OutputUnit = 'categorical'; end
    
    end
end

out = pre_out;

end