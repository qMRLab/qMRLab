function validatePanelUnits(Model)
% If the user loaded previous results generated in different units 
% then try to fit the data with conflicting Prot preferences, an 
% error will be thrown and user will be asked to reset the protocols.
%
% Here, Model is the Model received using getAppData. 

if ~isempty(fieldnames(Model.Prot))
% Check what user requested
usr = modelRegistry('get',Model.ModelName);
fnames = fieldnames(Model.Prot);
result = [];
for ii=1:length(fnames)
    fields = fieldnames(Model.Prot.(fnames{ii}));
    curFormat = Model.Prot.(fnames{ii}).Format;
    if ~iscell(curFormat)
        curFormat = cellstr(curFormat);
    end
    for jj =1:length(curFormat)
        
        loadedFieldUnit = cell2mat(getBareProtUnit(curFormat{jj},'symbol'));

        loadedField = cell2mat(getBareProtUnit(curFormat{jj},'fieldname'));
        
        userFieldUnit = usr.UnitBIDSMappings.Protocol.(fnames{ii}).(loadedField).Symbol;
        
        result = [result;isequal(loadedFieldUnit,userFieldUnit)];
    end
    
end

if ~any(result)
    response = false;
    prefs = getUserPreferences();
    if ~prefs.UnifyInputProtocolUnits.Enabled
        % This means that the input Protocol's won't be 
        % scaled. User can proceed as they see fit.
        response = true;
    end
elseif isempty(result)
    % There may not be anything to compare
    response = false;
else
    % Terminate
    response = true;
end

else
    % No Prot, no worries. 
    response = true; 
end

if ~response
    disp('=============================================================');
    disp('================== PROTOCOL UNIT MISMATCH ===================');
    disp('=============================================================');
    cprintf('red','<< ! >> Protocol units requested in /usr/preferences.json are not \n %s', ['consistent with'...
       'those currently loaded in the Options Panel.']);
   disp('=============================================================');
    cprintf('blue','<< i >> IF THE MISMATCH IS BECAUSE you loaded a FitResult saved with %s', ' different protocol units:');
    cprintf('magenta','        PLEASE RESET THE PROTOCOL by clicking the %s', ['|Default| button'...
                   'located at the bottom of the Options Panel.']);
    disp('');
    cprintf('blue','<< i >> IF THE MISMATCH IS BECAUSE you changed /usr/preferences.json %s', ' while qMRLab GUI was open:');
    cprintf('magenta','        PLEASE RESTART %s', 'qMRLab'); 
   disp('=============================================================');
   error('>>>>>>>> Please see the warning above =======================');
    
end
end