function test_suite=qMRusage_test
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;

function test_qMRusage
disp('TEST qMRusage...')
list = list_models;
for ii=1:length(list)
    Modelfun = str2func(list{ii});
    qMRusage(Modelfun(),'fit')
end
