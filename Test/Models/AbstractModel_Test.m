classdef (TestTags = {'Unit'}) AbstractModel_Test < matlab.unittest.TestCase

    properties
        tempFileName = 'tmp.mat'
        modelObject
    end
    
    methods (TestClassSetup)
         function initParPool(testCase)
           B0_DEM_batch;
           testCase.modelObject = Model;
        end
    end
    
    methods (TestClassTeardown)
        function clearTempFiles(testCase)
            if exist(testCase.tempFileName, 'file') == 2
                delete(testCase.tempFileName)
            end
        end
        
        function guiCleanup(testCase)
            close all
        end
    end
 
    methods (Test)
        function test_save_load_creates_identical_original_object(testCase)
            %% Prep
            originalObject = testCase.modelObject;
            
            %% Save
            testCase.modelObject.saveObj(testCase.tempFileName);
            
            %% Load
            loadedObject = testCase.modelObject;
            loadedObject.loadObj(testCase.tempFileName);
            
            %% Test
            assertEqual(testCase, originalObject, loadedObject);
        end
        
        function test_initialized_object_has_correct_version_val(testCase)
            assertEqual(testCase, testCase.modelObject.version, qMRLabVer);
        end
    end
    
end