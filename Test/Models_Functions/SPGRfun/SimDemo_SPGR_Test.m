classdef (TestTags = {'SPGR', 'Demo', 'Integration'}) SimDemo_SPGR_Test < matlab.unittest.TestCase

    properties
       qmrlabPath = cell2mat(regexp(cd, '.*qMRLab/', 'match'));
    end
    methods (TestClassSetup)
        function addqMRLabToPath(testCase)
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
            run([testCase.qmrlabPath, '/src/Models_Functions/SPGRfun/SimDemo_SPGR.m'])

            inputParams  = Sim.Param;
            outputParams = SimCurveResults;

            inputArr  = [inputParams.F  inputParams.kf  inputParams.R1f  inputParams.T2f  inputParams.T2r];
            outputArr = [outputParams.F outputParams.kf outputParams.R1f outputParams.T2f outputParams.T2r];

            %                                                 , # percent
            %                                                 . [F  kf R1f T2f T2r]
            testCase.verifyLessThan(pDiff(inputArr, outputArr), [30 30 30  30  30]);
        end
    end

end

function value = pDiff(inputVal, outputVal)
    value = abs((outputVal-inputVal)./inputVal).*100;
end
