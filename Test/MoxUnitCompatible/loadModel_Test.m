function test_suite=loadModel_Test
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;


function load_test

MethodList = list_models;

for im = 1:length(MethodList)
   % LOAD
   savedModel_fname = fullfile(fileparts(which('qMRLab')),'Test','MoxUnitCompatible','static_savedModelsforRetrocompatibility',[MethodList{im} '.qmrlab.mat']);
   savedModel = qMRloadObj(savedModel_fname);
   savedProps = objProps2struct(savedModel);
   % CREATE NEW OBJECT
   eval(['newModel = ' savedProps.ModelName ';']);
   newProps = objProps2struct(newModel);

   % TEST MISMATCH OF PROPERTIES:
   MSG=evalc('[~,LoadedModelextra,NewModelextra] = comp_struct(savedProps,newProps,3,0,inf);');
   
   % REPORT MISMATCH
   if ~isempty(LoadedModelextra)
       error(['Missing field in ' MethodList{im} ' : ' MSG]); 
   end
   if ~isempty(NewModelextra)
       error(['Constructed object has an unregistered property in ' MethodList{im} ' : ' MSG]);
   end
    
end

disp('Success: All fields are consistent.');