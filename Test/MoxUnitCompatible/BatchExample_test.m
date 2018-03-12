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

% ======================================== TRAVIS CACHE SELECTION

% Set <<cahceState>> to:

%  <false> if cache (for OSF data) is cleared or to be updated
%  <true> if the same cache (for OSF data) is still in use

cacheState = false;
% -----------------------------------------------------

% This directory will be created on Travis server. See .travis.yml
tmpDir = '/home/travis/build/neuropoly/qMRLab/osfData';
cd(tmpDir)

Modellist = list_models';
for iModel = 1:length(Modellist)
    disp('===============================================================')
    disp(['Testing: ' Modellist{iModel} ' BATCH...'])
    disp('===============================================================')

    
    eval(['Model = ' Modellist{iModel}]);
    
  
    if cacheState
        % Navigate to the batch example folders 
        cd([tmpDir filesep Modellist{iModel} '_demo']);
    end
    
    
    
    if ~cacheState
        % Generate batch w/ downloading data
        qMRgenBatch(Model,pwd)
    elseif cacheState
        % Generate batch w/o downloading data
        qMRgenBatch(Model,pwd,0)
    end
    
 
    
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

