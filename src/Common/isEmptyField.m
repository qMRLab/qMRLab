% Helper function to query whether a struct field is empty 
% provided that the field exists (false otherwise). 
% 
% Inputs:
%   inStruct        (type struct) The input struct       
%   fieldName       (type string) The field name for which the 
%                                 inStruct is queried  
%
% Outputs:
%   output         (type boolean) false if the field is not empty 
%                                 OR does not exist 
%                                 true otherwise.       
%
% Written by: Juan Velazques-Reyes
% October, 2021 

function output = isEmptyField(inStruct,fieldName)
    if isfield(inStruct,fieldName) && ~isempty(inStruct.(fieldName))
        output = false;
    else
        output = true;
    end
end