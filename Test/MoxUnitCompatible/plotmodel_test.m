function test_suite=test_Models
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;

function test_plotmodel
disp('testing plotmodel...')
MethodList = list_models;
for im = 1:length(MethodList)
    Model = str2func(MethodList{im}); Model = Model();
    if ~Model.voxelwise, continue; end
    disp([class(Model) '...'])
	Model.plotmodel;
end