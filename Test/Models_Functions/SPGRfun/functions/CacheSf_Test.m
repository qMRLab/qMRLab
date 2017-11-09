classdef (TestTags = {'SPGR', 'Unit'}) CacheSf_Test < matlab.unittest.TestCase

    properties
        protocolFileLocation = 'savedprotocols/demo_SPGR_Protocol_For_CacheSf_Test.mat';
        Prot;
        expectedFields = {'values','angles', 'offsets', 'T2f', 'PulseShape', 'PulseTrf', 'PulseOpt'}';
    end
    
    methods (TestClassSetup)
        function load_protocol(testCase)
           testCase.Prot = load(testCase.protocolFileLocation);
        end
    end
    
    methods (TestClassTeardown)
    end
    
    methods (Test)
         function test_CacheSf_throws_error_for_bad_arg_class(testCase)
             % CacheSf should only accept arguments of type 'struct' or
             % 'char', otherwise an error should be thrown.
             
             invalidArg = 1234;
             
             % Set an arbitrary default testError identifier for test.
             testError.identifier='No Error';

             try 
                 CacheSf(invalidArg)
             catch ME
                 testError = ME;
             end
             
             assertEqual(testCase, testError.identifier, 'qMRLab:CacheSf:unknownArgument');
         end
         
         function test_CacheSf_returns_struct_with_expected_fields(testCase)
             testCase.Prot.Sf = CacheSf(testCase.Prot);
             
             assertEqual(testCase, fields(testCase.Prot.Sf), testCase.expectedFields);
         end
    end
    
end