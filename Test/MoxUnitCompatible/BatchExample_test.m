function test_suite=BatchExample_test
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;

function TestSetup
setenv('ISTRAVIS','1') % go faster! Fit only 2 voxels in FitData.m

function test_batch
curdir = pwd;
tmpDir = tempname;
mkdir(tmpDir);
cd(tmpDir)
setenv('ISTRAVIS','1')
Modellist = list_models';
for iModel = 1:length(Modellist)
    disp('===============================================================')
    disp(['Testing: ' Modellist{iModel} '...'])
    disp('===============================================================')

    eval(['Model = ' Modellist{iModel}]);
    qMRgenBatch(Model,pwd)
    
    eval([Modellist{iModel} '_batch'])
    
    cd ..
end
setenv('ISTRAVIS','')
cd(curdir)
rmdir(tmpDir,'s')

function TestTeardown
setenv('ISTRAVIS','0')

