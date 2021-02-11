function test_suite=qMRusage_test
try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions=localfunctions();
catch % no problem; early Matlab versions can use initTestSuite fine
end
initTestSuite;

function test_versionChecker
disp('TEST published vs current version')
state = versionChecker;
% This means that the published release is somehow ahead of development, which should not be.
assertEqual(state,[],'Published version is ahead of the version specified in the version.txt of this branch.');
