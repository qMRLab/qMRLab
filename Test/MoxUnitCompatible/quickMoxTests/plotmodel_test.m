function test_suite=plotmodel_test
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;

function TestSetup
setenv('ISDISPLAY','0') % go faster! Fit only 2 voxels in FitData.m

function test_plotmodel
disp('testing plotModel...')
MethodList = list_models;
for im = 1:length(MethodList)
    Model = str2func(MethodList{im}); Model = Model();
    if ~Model.voxelwise, continue; end
    disp([class(Model) '...'])
	Model.plotModel;
end

function TestTeardown
setenv('ISDISPLAY','') % go faster! Fit only 2 voxels in FitData.m
