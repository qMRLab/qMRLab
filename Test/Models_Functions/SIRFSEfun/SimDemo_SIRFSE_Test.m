classdef (TestTags = {'SIRFSE', 'Demo', 'Integration'}) SimDemo_SIRFSE_Test < matlab.unittest.TestCase

    methods (Test)
        function testFittedParamsNearInputValues(testCase)
            [Sim, SimCurveResults] = SimDemo_SIRFSE();

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
