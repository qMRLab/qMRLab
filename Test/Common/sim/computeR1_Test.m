classdef (TestTags = {'Unit', 'SPGR', 'qMT'}) computeR1_Test < matlab.unittest.TestCase

    properties
        F   = 0.12; % Pool-size ratio
        kf  = 3.5;  % Exchange rate constant
        R1r = 1.0;  % Longitudinal relaxation rate of the restricted pool
        
        R1obs = 1/0.900; % Observed longitudinal relaxation rate, 1/T1.
    end
    
    methods (TestClassSetup)
    end
    
    methods (TestClassTeardown)
    end
    
    methods (Test)
        function test_computeR1_returns_expected_analytical_value(testCase)
            % Prep properties
            F = testCase.F;
            kf = testCase.kf;
            R1r = testCase.R1r;
            
            R1obs = testCase.R1obs;
            
            %
            
            Param = struct('F', F, 'kf', kf, 'R1r', R1r);
            
            %
            actualValue = computeR1(Param, R1obs);
            
            expectedValue = R1obs - kf*(R1r - R1obs) / (R1r - R1obs + kf/F); % Eq. 7 of Sled & Pike 2001, DOI: 10.1002/mrm.1278
                                                                             % with R1f factored out of the right-hand side.

            testCase.assertEqual(actualValue, expectedValue);
        end
                 
    end
    
end