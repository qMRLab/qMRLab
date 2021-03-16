function Out = unitScaleFitResults(direction,FitResults)

Out = FitResults;

% Introduced in v2.5.0. Do not perform for 
% FitResults of older versions.
if ~checkanteriorver(FitResults.Version,[2 4 9])
     
switch direction
    
    case 'toOriginalUnits'
        
        % Division by the ScaleFactor 
        for ii=1:length(FitResults.fields)
            Out.(FitResults.fields{ii}) = FitResults.(FitResults.fields{ii})./FitResults.UnitBIDSMappings.Output.(FitResults.fields{ii}).ScaleFactor;
        end

        
    case 'toUserUnits'
        
        % Multiply with the ScaleFactor
        for ii=1:length(FitResults.fields)
            Out.(FitResults.fields{ii}) = FitResults.(FitResults.fields{ii}).*FitResults.UnitBIDSMappings.Output.(FitResults.fields{ii}).ScaleFactor;
        end
        
end

end
end