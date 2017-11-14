function test_suite=BatchExample_test
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;

function test_batch
curdir = pwd;
disp('testing batchExamples... (FAILURE MIGHT CORRESPOND TO COMPATIBILITY PROBLEM (e.g. variable name changed), edit qMRpatch.m ). ')
BatchDir = [fileparts(which('qMRLab.m')) filesep 'Data'];
[BatchList, pathmodels] = sct_tools_ls([BatchDir filesep '*batch.m'],0,0,2,1);
setenv('ISTRAVIS','1') % go faster! Fit only 2 voxels
for im = 1:length(BatchList)
    cd(pathmodels{im})
    disp('===============================================================')
    disp(['Testing: ' BatchList{im} '...'])
    disp('===============================================================')
    eval(BatchList{im})
    disp ..ok
end
cd(curdir)
