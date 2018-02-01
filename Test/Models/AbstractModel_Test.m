classdef (TestTags = {'Unit'}) AbstractModel_Test < matlab.unittest.TestCase

    properties
        tempFileName = 'tmp.mat'
        modelObject
    end
    
    methods (TestClassSetup)
         function initParPool(testCase)
           testCase.modelObject = b0_dem;
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
            %
            
            originalObject = testCase.modelObject;
            
            %% Save
            %
            
            testCase.modelObject.saveObj(testCase.tempFileName);
            
            %% Load
            %
            
            loadedObject = testCase.modelObject;
            loadedObject.loadObj(testCase.tempFileName);
            
            %% Test
            %
            assertEqual(testCase, originalObject, loadedObject);
        end
        
        function test_initialized_object_has_correct_version_val(testCase)
            assertEqual(testCase, testCase.modelObject.version, qMRLabVer);
        end
        
        function test_load_fails_for_bad_version(testCase) %Temporary before being handled
             % Bad first argument parent type
             testError.identifier='No Error';
             
             testObject = testCase.modelObject;
             testObject.saveObj(testCase.tempFileName);
             
             % Change version to bad one.
             testObject.version = [0 0 0];
             
             try 
                 testObject.loadObj(testCase.tempFileName);
             catch ME
                 testError = ME;
             end
             
             assertEqual(testCase, testError.identifier, 'AbstractModel:VersionMismatch');
        end
        
                
        function test_save_load_retains_same_version(testCase) %Temporary before being handled
            %% Prep
            %
            
            originalObject = testCase.modelObject;
            originalVersion = originalObject.version;
            
            %% Save
            %
            
            testCase.modelObject.saveObj(testCase.tempFileName);
            
            %% Load
            %
            
            loadedObject = testCase.modelObject;
            loadedObject.loadObj(testCase.tempFileName);
            loadedVersion = loadedObject.version;
            
             assertEqual(testCase, originalVersion, loadedVersion);
        end
    end
    
end

