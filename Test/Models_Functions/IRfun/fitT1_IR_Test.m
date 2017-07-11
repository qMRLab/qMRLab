%         TestTags are useful for identifying what kind of test you're coding, as you might only want to run certain tests that are related. 
classdef (TestTags = {'T1', 'Demo', 'Integration'}) fitT1_IR_Test < matlab.unittest.TestCase % It's convention to name the test file (filename being tested)_Test.m
    
    properties % Test class variabes; useful for common parameters between tests.
        IRdata
        Mask
        TI
    end
    
    methods (TestClassSetup) % Usually used to setup common testing variables, or loading data.
        function load_test_data(testCase)
            testData = load('Data/IR_demo/IR_demo.mat'); % Place full relative path, in case the file goes missing or there is a conflict
            
            % Set class properties
            testCase.IRdata = testData.IRdata;
            testCase.Mask = testData.Mask;
            testCase.TI = testData.TI;

        end
    end
    
    methods (TestClassTeardown) % This could be used to delete any files created during the test execution.
    end
    
    methods (Test) % Each test is it's own method function, and takes testCase as an argument.

        function test_IRfun_returns_near_expected_median_of_test_data(testCase) % Use very descriptive test method names
            %% Prepare for test
            %
            method='Magnitude';
            
            T1 = zeros(size(testCase.IRdata,1), size(testCase.IRdata,2));
            
            %% Fit voxels
            %
            for xx = 1:size(testCase.IRdata,1)
                for yy = 1:size(testCase.IRdata,2)
                    
                    if testCase.Mask(xx,yy) % Skip masked voxels
                        [T1(xx, yy), ~, ~, ~] = fitT1_IR(testCase.IRdata(xx, yy, :), testCase.TI, method);
                    end
                    
                end
            end
            
            %% Check the fit
            %
                        
            % Mask data
            maskedT1 = T1(:).*testCase.Mask(:);
            maskedT1(maskedT1 == 0) =[];
            
            expectedMedian = 748; % in s, Value was identified under stable working conditions.
            actualMedian = median(maskedT1(:));
            
            % Assert functions are the core of unit tests; if it fails,
            % test log will return failed tests and details.
            assertTrue(testCase, abs(actualMedian-expectedMedian) < 50); % This will alert us if a code change ever produces a fit 
                                                                         % with a median lower than 700 or greater than 800, signaling
                                                                         % a potential bug.
        end
    end
    
end
