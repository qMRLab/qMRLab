%         TestTags are useful for identifying what kind of test you're coding, as you might only want to run certain tests that are related. 
classdef (TestTags = {'T1', 'Demo', 'Integration'}) fitT1_IR_Test < matlab.unittest.TestCase % It's convention to name the test file (filename being tested)_Test.m
    
    properties % Test class variabes; useful for common parameters between tests.
        IRdata
        Mask
        TI
    end
    
    methods (TestClassSetup) % Usually used to setup common testing variables, or loading data.
        function load_test_data(testCase)
        % Downloads demo data for the inversion recovery model, 
        % and loads it into class properties for use in the test methods.

            % Messing with pwd is bad manners, so restore it at the end no matter what
            here = pwd;
            goBack = onCleanup(@() cd(here));

            Model = inversion_recovery();
            baseDir = tempdir();
            demoDir = fullfile(baseDir, [Model.ModelName '_demo']);

            if ~isfolder(demoDir)
                fprintf('Downloading demo data for %s model...', Model.ModelName);
                downloadData(Model, baseDir);
            end
            cd(demoDir);
            
            % Set class properties
            testCase.IRdata = load('inversion_recovery_data/IRData.mat').IRData;
            testCase.Mask = load('inversion_recovery_data/Mask.mat').Mask;
            testCase.TI = load('FitResults/FitResults.mat').Protocol.IRData.Mat;
            fprintf('Demo data loaded successfully!');
        end
    end
    
    methods (TestClassTeardown) % This could be used to delete any files created during the test execution.
    end
    
    methods (Test) % Each test is it's own method function, and takes testCase as an argument.

        function test_IRData_is_available(testCase)
            testCase.verifyNotEmpty(testCase.IRdata, 'IRdata should not be empty');
        end

        function test_IRfun_returns_near_expected_median_of_test_data(testCase) % Use very descriptive test method names
            
            method='Magnitude';
            
            %% Fit (masked) voxels
            fprintf('Fitting T1 values for masked voxels using %s method...', method);
            [xx, yy] = find(testCase.Mask);
            [maskedT1, ~, ~, ~] = arrayfun(@(x, y) fitT1_IR(testCase.IRdata(x, y, :), testCase.TI, method), xx, yy);
            
            %% Check the fit
            expectedMedian = 748; % in s, Value was identified under stable working conditions.
            actualMedian = median(maskedT1(:));
            
            % This will alert us if a code change ever produces a fit 
            % with a median lower than 700 or greater than 800, signaling
            % a potential bug.
            testCase.verifyEqual(actualMedian, expectedMedian, 'AbsTol', 50); 
        end
    end
end
