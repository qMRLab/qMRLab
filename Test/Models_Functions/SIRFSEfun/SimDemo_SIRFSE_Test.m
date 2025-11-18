classdef (TestTags = {'SIRFSE', 'Demo', 'Integration'}) SimDemo_SIRFSE_Test < matlab.unittest.TestCase

    properties
       qmrlabPath = cell2mat(regexp(cd, '.*qMRLab/', 'match'));
    end
    methods (TestClassSetup)
        function addqMRILabToPath(testCase)
            addpath(genpath(testCase.qmrlabPath));
        end
    end

    methods (TestClassTeardown)
        function removeqMRILabFromPath(testCase)
            clear all, close all
        end
    end

    methods (Test)
        function testFittedParamsNearInputValues(testCase)
            run([testCase.qmrlabPath, '/src/Models_Functions/SIRFSEfun/SimDemo_SIRFSE.m'])

            inputParams  = Sim.Param;
            outputParams = SimCurveResults;

            inputArr  = [inputParams.F  inputParams.kf  inputParams.R1f  inputParams.R1r];
            outputArr = [outputParams.F outputParams.kf outputParams.R1f outputParams.R1r];

            %                                                 , # percent
            %                                                 . [F  kf R1f R1r]
            testCase.verifyLessThan(pDiff(inputArr, outputArr), [30 30 30 30]);
        end
    end

end

function value = pDiff(inputVal, outputVal)
    value = abs((outputVal-inputVal)./inputVal).*100;
end
