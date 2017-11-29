
function load_test

[pathstr,~,~]=fileparts(which('load_test.m'));
cd (pathstr);
MethodList = list_models;

for i = 1:length(MethodList)
    
   savedModel = load([MethodList{i} '.qmrlab.mat']);
   eval(['newModel = ' savedModel.ModelName ';']);
  
   newProps = properties(newModel);
  
   % Saved method is a struct with properties only.
   
   savedProps = fieldnames(savedModel);
   
   idx1 = ismember(newProps,savedProps);
   idx2 = ismember(savedProps,newProps);
   
   
   if not(all(idx2)) && length(idx2)>length(idx1) % This means that newProps is missing something
   loc = find(idx2 == 0);
   error(['Missing field in ' MethodList{i} ' : ' savedProps{loc}]);       
   end
   
   if not(all(idx1)) && length(idx2)<length(idx1) % This means that there is something new.
   loc = find(idx1 == 0);
   error(['Constructed object has an unregistered property in ' MethodList{i} ' : ' newProps{loc}]);       
   end
   
   if not(all(idx1)) && length(savedProps) == length(newProps) % More complicated. Mistmatch. 
   loc = find(idx1 == 0);
   error(['There is mismatch in ' MethodList{i} ' : ' newProps{loc}]);   
   end
   
    
end

disp('Success: All fields are consistent.');




end