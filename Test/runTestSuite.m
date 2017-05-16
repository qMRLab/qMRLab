function [testsResults] = runTestSuite(suiteTag)
%runtests: Run tagged tests from all subdirectories
%   suiteTag: String matching tags from test classes in subdirectories
%
    import matlab.unittest.TestSuite;
    fullSuite = TestSuite.fromFolder(pwd, 'IncludingSubfolders', true);
    persistenceSuite = fullSuite.selectIf('Tag',suiteTag);
    testsResults = run(persistenceSuite)
end

