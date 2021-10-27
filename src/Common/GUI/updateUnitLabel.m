function updateUnitLabel(handles,viewException,registryStruct,unitDefsStruct,usrPrefsStruct)
% Update the unit label based on the value of the SourcePop dropdown menu. 
% When the CurrentData of the handles points to method x, but method y is
% selected from the dropdown, the SourcePop set to ' ' to inform this
% function.
% text101 is the UIComponent responsible for displaying the unit.

try
Method = GetMethod(handles);
if nargin>2
    % Use already read configs 
    reg = modelRegistry('get',Method,'registryStruct',registryStruct,'unitDefsStruct',unitDefsStruct,'usrPrefsStruct',usrPrefsStruct);
else
    % Call by reading jsons
    reg = modelRegistry('get',Method);
end
if ~strcmp(get(handles.SourcePop,'String'),' ')
cur_sel = handles.SourcePop.String{get(handles.SourcePop,'Value')};
if ismember(cur_sel,fieldnames(reg.UnitBIDSMappings.Output))
    dispUnit = reg.UnitBIDSMappings.Output.(cur_sel);
else
    dispUnit = reg.UnitBIDSMappings.Input.(cur_sel);
end
 set(handles.text101,'String',sprintf([dispUnit.Label '\n' dispUnit.Symbol]));
else
 set(handles.text101,'String','');    
end

% Either user executed fit or loaded prev results.
if ~isempty(handles.CurrentData) && isfield(handles.CurrentData,'Version') && ~viewException
    if checkanteriorver(handles.CurrentData.Version, [2 4 9])
        set(handles.text101,'String',sprintf(['n/a \nv' num2str(handles.CurrentData.Version(1)) '.' num2str(handles.CurrentData.Version(2)) '.' num2str(handles.CurrentData.Version(3))])); 
    end
    
    % If loaded results > v2.5.0 do not use current user's settings, but
    % use those coming with the FitResults.
    try
    if isfield(handles.CurrentData,'UnitBIDSMappings')
        reg.UnitBIDSMappings = handles.CurrentData.UnitBIDSMappings;
        if ~strcmp(get(handles.SourcePop,'String'),' ')
        cur_sel = handles.SourcePop.String{get(handles.SourcePop,'Value')};
        if ismember(cur_sel,fieldnames(reg.UnitBIDSMappings.Output))
            dispUnit = reg.UnitBIDSMappings.Output.(cur_sel);
        else
            dispUnit = reg.UnitBIDSMappings.Input.(cur_sel);
        end
         set(handles.text101,'String',sprintf([dispUnit.Label '\n' dispUnit.Symbol]));
        else
         set(handles.text101,'String','');    
        end

        
    end
    catch
      set(handles.text101,'String','Not registered');    
    end
end
catch
  set(handles.text101,'String','Not registered');    
end
