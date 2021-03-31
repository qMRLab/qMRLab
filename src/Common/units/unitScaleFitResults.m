function Out = unitScaleFitResults(direction,FitResults)

Out = FitResults;

% Introduced in v2.5.0. Do not perform for 
% FitResults of older versions.
if ~checkanteriorver(FitResults.Version,[2 4 9])
     
switch direction
    
    case 'toOriginalUnits'
        
        % Division by the ScaleFactor 
        for ii=1:length(FitResults.fields)
            try
                Out.(FitResults.fields{ii}) = FitResults.(FitResults.fields{ii})./FitResults.UnitBIDSMappings.Output.(FitResults.fields{ii}).ScaleFactor;
            catch
                % Assumption:
                % Missing fields caought in this exception are the partial
                % output names such as SE_TE*. Only those will be handled 
                % here. If a field is missing due to incomplete model 
                % registry, it MUST fail. 
               registeredTag = isPartialField(FitResults.fields{ii},FitResults.Model.ModelName);
               if ~isempty(registeredTag)
                   registeredTag = cell2mat(registeredTag);
                   Out.(FitResults.fields{ii}) = FitResults.(FitResults.fields{ii})./FitResults.UnitBIDSMappings.Output.(registeredTag).ScaleFactor;
               else
                   error(['No partial match or registered tag has been found for ' FitResults.fields{ii} ' in the model ' FitResults.Model.ModelName]);
               end
               
            end
        end

        
    case 'toUserUnits'
        
        % Multiply with the ScaleFactor
        for ii=1:length(FitResults.fields)
            try
                Out.(FitResults.fields{ii}) = FitResults.(FitResults.fields{ii}).*FitResults.UnitBIDSMappings.Output.(FitResults.fields{ii}).ScaleFactor;
            catch
                registeredTag = isPartialField(FitResults.fields{ii},FitResults.Model.ModelName);
               if ~isempty(registeredTag)
                   registeredTag = cell2mat(registeredTag);
                   Out.(FitResults.fields{ii}) = FitResults.(FitResults.fields{ii}).*FitResults.UnitBIDSMappings.Output.(registeredTag).ScaleFactor;
               else
                   error(['qMRLab Developer: No partial match or registered tag has been found for ' FitResults.fields{ii} ' in the model ' FitResults.Model.ModelName]);
               end
            end
        end
        
end

end
end

function [registeredTag] = isPartialField(curFieldName,modelName)

register = modelRegistry('get',modelName);
fnms = fieldnames(register.Registry.Outputs);

% Assumption is that the partial matchs should happen
% in the first 4 chars. If you need to come up with another 
% partial matchin convention, please edit here. 

idxn = cellfun(@(S) strncmp(curFieldName,S,4), fnms);

% This means that there's a registered output field that 
% matches the currentFieldName at the first 4 chars.
if any(idxn)
    % Returns cell if exists
    registeredTag = fnms(idxn);
    if length(registeredTag) > 1
        warning('More than one partial match has been found in the registry. Please consider using unique tag names for the partial match templates (e.g. S0_TE).');
    end
else
    % Otherwise return empty to signal interruption.
    registeredTag = [];
end

end