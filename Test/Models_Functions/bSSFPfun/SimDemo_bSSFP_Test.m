classdef (TestTags = {'bSSFP', 'Demo', 'Integration'}) SimDemo_bSSFP_Test < matlab.unittest.TestCase

    properties
       qmrilabPath = cell2mat(regexp(cd, '.*qMRILab/', 'match'));
    end
    methods (TestClassSetup)
        function addqMRILabToPath(testCase)
            addpath(genpath(testCase.qmrilabPath));
        end
    end

    methods (TestClassTeardown)
        function removeqMRILabFromPath(testCase)
            clear all, close all
        end
    end

    methods (Test)
        function testFittedParamsNearInputValues(testCase)
            run([testCase.qmrilabPath, '/Models_Functions/bSSFPfun/SimDemo_bSSFP.m'])

            inputParams  = Sim.Param;
            outputParams = SimCurveResults;

            inputArr  = [inputParams.F  inputParams.kf  inputParams.R1f  inputParams.R1r inputParams.T2f];
            outputArr = [outputParams.F outputParams.kf outputParams.R1f  outputParams.R1r outputParams.T2f];

            %                                                 , # percent
            %                                                 . [F  kf R1f R1r T2f]
            testCase.verifyLessThan(pDiff(inputArr, outputArr), [30 30 30  30 30]);
        end
    end

end

function value = pDiff(inputVal, outputVal)
    value = abs((outputVal-inputVal)./inputVal).*100;
end
