classdef downloadData_Test < matlab.unittest.TestCase

    properties
        path = '';
        localfunctions = struct();
    end

    properties (TestParameter)
        method = {'auto', 'curl', 'wget', 'websave', 'request', 'urlwrite'};
        methodRealData = {'auto', 'request'}
    end

    methods (TestClassSetup)
        function setupMethods(testCase)
            % This is a backdoor to access the local functions for unit testing:
            % https://uk.mathworks.com/matlabcentral/answers/1915540-can-i-access-local-functions-for-unit-testing
            testCase.localfunctions = downloadData('localfunctions');
        end
        function makeTestDir(testCase)
            testCase.path = fullfile(tempdir(), 'downloadData_Test');
            mkdir(testCase.path);
        end
    end

    methods (TestClassTeardown)
        function removeTestDir(testCase)
            rmdir(testCase.path, 's');
        end
    end

    methods(Test)
        function test_method(testCase, method)
            % Download a plain HTML file using each method

            % skip wget/curl if commands are not available on the system
            if ismember(method, {'wget', 'curl'})
                testCase.assumeTrue(system([method, ' --version']) == 0);
            end

            downladFunction = testCase.localfunctions.(method);
            file = fullfile(testCase.path, [method '_test.html']);
            downladFunction('http://example.com', file, 30);
            testCase.verifyTrue(exist(file, 'file') == 2);
        end

        function test_model_demo_download(testCase, methodRealData)
            % Test the full downloadData function with a model's demo data

            % downloadData will cd into the demo folder. Make sure we go back.
            here = pwd();
            goBack = onCleanup(@() cd(here));

            % b1_dam has the smallest demo dataset.
            % Using a mock structure here to avoid dependency on the actual model.
            mdl = struct('ModelName', 'b1_dam', 'onlineData_url', 'https://osf.io/mw3sq/download?version=3');

            dataPath = downloadData(mdl, testCase.path, methodRealData, 3);

            testCase.verifyTrue(exist(dataPath,'dir') == 7, 'Failed to find data directory');
            fitResultsPath = fullfile(fileparts(dataPath),'FitResults','FitResults.mat');
            testCase.verifyTrue(exist(fitResultsPath,'file') == 2, 'Failed to find unzipped FitResults.mat file');
        end

        function test_model_bad_download(testCase)
            % Test a mock model with an invalid URL

            here = pwd();
            goBack = onCleanup(@() cd(here));

            mdl = struct('ModelName', 'mock', 'onlineData_url', 'http://badurl');
            testCase.verifyError(@() downloadData(mdl, testCase.path, 'auto', 1, 3), 'qMRLab:download:fail');
        end
    end
end
