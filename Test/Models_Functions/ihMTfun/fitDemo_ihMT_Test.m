%         TestTags are useful for identifying what kind of test you're coding, as you might only want to run certain tests that are related. 
classdef (TestTags = {'ihMT', 'Demo', 'Integration'}) fitDemo_ihMT_Test < matlab.unittest.TestCase % It's convention to name the test file (filename being tested)_Test.m
    
    properties
        qmrlabPath = cell2mat(regexp(cd, '.*qMRLab/', 'match'));
    end
    
    methods (TestClassSetup) % Usually used to setup common testing variables, or loading data.
        function addqMRLabToPath(testCase)
            addpath(genpath(testCase.qmrlabPath));
        end
    end
    
    methods (TestClassTeardown) % This could be used to delete any files created during the test execution.
    end
    
    methods (Test) % Each test is it's own method function, and takes testCase as an argument.

        function test_M0appVSRI_returns_near_expected_mean_of_M0app(testCase) % Use very descriptive test method names
            %% Run code
            run([testCase.qmrlabPath, '/Models_Functions/ihMTfun/fitDemo/fitDemo_ihMT.m'])
            
            %% Check the fit
            expectedMean = 0.10; % Value obtained manually
            actualMean = mean2(M0_app_dual);
            
            % Assert functions are the core of unit tests; if it fails,
            % test log will return failed tests and details.
            assertTrue(testCase, abs(actualMean-expectedMean) < 0.1); % This will alert us if a code change ever produces a fit 
                                                                         % with a median lower than 700 or greater than 800, signaling
                                                                         % a potential bug.
        end
    end
    
end