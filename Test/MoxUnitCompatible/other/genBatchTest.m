function test_suite=genBatchTest
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;

function test_DOC
disp('TEST batch gen');
orgDir = pwd;

% Create a temporary folder on machine 
tmpDir = tempname;
mkdir(tmpDir);
cd(tmpDir);
disp('DOC case');
setenv('ISCITEST','0'); 
setenv('ISDOC','1');
    Modellist = list_models';
    for iModel = 1:length(Modellist)
        eval(['Model = ' Modellist{iModel}]);
        qMRgenBatch(Model,pwd,1);
    end
setenv('ISDOC','');
setenv('ISCITEST','');
unix('ls -l');
cd(orgDir);
rmdir(tmpDir,'s');

function test_USR
disp('TEST batch gen');
orgDir = pwd;

% Create a temporary folder on machine 
tmpDir = tempname;
mkdir(tmpDir);
cd(tmpDir);
disp('DOC case');
setenv('ISCITEST',''); 
setenv('ISDOC','');
    Modellist = list_models';
    for iModel = 1:length(Modellist)
        eval(['Model = ' Modellist{iModel}]);
        qMRgenBatch(Model,pwd,1);
    end
unix('ls -l');
cd(orgDir);
rmdir(tmpDir,'s');

function test_TEST
disp('TEST batch gen');
orgDir = pwd;

% Create a temporary folder on machine 
tmpDir = tempname;
mkdir(tmpDir);
cd(tmpDir);
disp('DOC case');
setenv('ISCITEST','1'); 
    Modellist = list_models';
    for iModel = 1:length(Modellist)
        eval(['Model = ' Modellist{iModel}]);
        qMRgenBatch(Model,pwd,1);
    end
setenv('ISCITEST','');     
unix('ls -l');
cd(orgDir);
rmdir(tmpDir,'s');
