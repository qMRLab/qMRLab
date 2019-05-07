function test_suite = genJN_test(rstDir)

try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end

initTestSuite;
    
function TestSetup
setenv('ISDISPLAY','0')


function test_genJN
    disp('Testing automatic JN create for all models')
    
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
        disp(['Creating : ' Modellist{iModel} ' Jupyter Notebook'])
        disp('===============================================================')
    
    
    eval(['Model = ' Modellist{iModel}]);

    qMRgenJNB(Model,pwd);
        
    end
    cd(curdir)

function TestTeardown
setenv('ISDISPLAY','') % go faster! Fit only 2 voxels in FitData.m


    

