classdef (TestTags = {'Unit', 'SPGR', 'qMT'}) hard_pulse_Test < matlab.unittest.TestCase

    properties
    end
    
    methods (TestClassSetup)
    end
    
    methods (TestClassTeardown)
    end
    
    methods (Test)
        function test_pulse_returns_single_datatype(testCase)
            timeRange = -10:0.01:10;
            Trf = 3;
            PulseOpt = [];
            
            pulse = hard_pulse(timeRange, Trf, PulseOpt);
            
            testCase.assertInstanceOf(pulse, 'double')
        end     
    end
    
end