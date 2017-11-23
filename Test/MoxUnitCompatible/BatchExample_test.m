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
disp('testing batchExamples... (FAILURE MIGHT CORRESPOND TO COMPATIBILITY PROBLEM (e.g. variable name changed), edit qMRpatch.m ). ')
BatchDir = [fileparts(which('qMRLab.m')) filesep 'Data'];
[BatchList, pathmodels] = sct_tools_ls([BatchDir filesep '*batch.m'],0,0,2,1);
for im = 1:length(BatchList)
    cd(pathmodels{im})
    disp('===============================================================')
    disp(['Testing: ' BatchList{im} '...'])
    disp('===============================================================')
    tmpDir = tempname;
    mkdir(tmpDir);
    copyfile(fullfile(pathmodels{im}(1:end-1),'*'),tmpDir)
    cd(tmpDir)
    if not(strcmp(BatchList{im},'NoiseLevel_batch')) && not(strcmp(BatchList{im},'CHARMED_batch')) && not(strcmp(BatchList{im},'NODDI_batch')) && not(strcmp(BatchList{im},'MTV_batch'))
    eval(BatchList{im})
    end
    if moxunit_util_platform_is_octave
        confirm_recursive_rmdir(0); % for octave
    end
    rmdir(tmpDir,'s')
    disp ..ok
end
cd(curdir)

function TestTeardown
setenv('ISTRAVIS','0')

