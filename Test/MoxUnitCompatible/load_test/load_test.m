function test_suite=loadModel_Test
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;


function load_test

MethodList = list_models;

for im = 1:length(MethodList)
   savedModel_fname = fullfile(fileparts(which('qMRLab')),'Test','MoxUnitCompatible','static_savedModelsforRetrocompatibility',[MethodList{im} '.qmrlab.mat']);
   savedProps = load(savedModel_fname);
   eval(['newModel = ' savedProps.ModelName ';']);
  
   newProps = objProps2struct(newModel);

   % Saved method is a struct with properties only.
   
   [~,LoadedModelextra,NewModelextra] = comp_struct(savedProps,newProps,3,0,inf);
%    idx1 = ismember(newProps,savedProps);
%    idx2 = ismember(savedProps,newProps);
   
   newMsg = evalc('NewModelextra');
   loadMsg = evalc('LoadedModelextra');
   if ~isempty(LoadedModelextra)
       error(['Missing field in ' MethodList{im} ' : ' newMsg loadMsg]); 
   end
   if ~isempty(NewModelextra)
       error(['Constructed object has an unregistered property in ' MethodList{im} ' : ' newMsg loadMsg]);
   end
    
end

disp('Success: All fields are consistent.');