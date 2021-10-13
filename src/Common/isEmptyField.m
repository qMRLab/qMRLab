%isEmptyField function
%Checks if a field of a structure exists AND if that field is not empty
function output = isEmptyField(structName,fieldName)
    if isfield(structName,fieldName) && ~isempty(structName.(fieldName))
        output = false;
    else
        output = true;
    end