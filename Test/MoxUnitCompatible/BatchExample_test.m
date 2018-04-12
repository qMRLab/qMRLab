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

if exist('/home/travis','dir')
    tmpDir = '/home/travis/build/neuropoly/qMRLab/osfData';
else
    tmpDir = tempdir;
end
mkdir(tmpDir);
cd(tmpDir)

Modellist = list_models';
for iModel = 1:length(Modellist)
    disp('===============================================================')
    disp(['Testing: ' Modellist{iModel} ' BATCH...'])
    disp('===============================================================')
    
    
    eval(['Model = ' Modellist{iModel}]);
    
    
    
    
    
    
    
    qMRgenBatch(Model,pwd)
    
    
    
    
    % Test if any dataset exist
    isdata = true;
    try
        Model.onlineData_url;
    catch
        isdata = false;
    end
    
    % Run Batch
    if isdata
        starttime = tic;
        eval([Modellist{iModel} '_batch'])
        toc(starttime)
    end
    close all
    cd ..
    
end
cd(curdir)


function TestTeardown
setenv('ISTRAVIS','0')

