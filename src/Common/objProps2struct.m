function objStruct = objProps2struct(obj)
% objStruct = obj2struct(obj)

objectProperties = fieldnames(obj);
objectProperties(strcmp(objectProperties,'onlineData_filename'))=[];
objectProperties(strcmp(objectProperties,'onlineData_url'))=[];

objStruct = struct();
%Loop through all object properties
for propIndex = 1:length(objectProperties)
    
    % Assign object property value to identically named struct field.
    objStruct.(objectProperties{propIndex}) = obj.(objectProperties{propIndex});
end
% Add Model Name
objStruct.ModelName = class(obj);
