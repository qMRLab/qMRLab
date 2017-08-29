classdef (TestTags = {'Unit'}) addNoise_Test < matlab.unittest.TestCase

    properties
    end
    
    methods (TestClassSetup)
    end
    
    methods (TestClassTeardown)
    end
    
    methods (Test)
        function test_addNoise_throws_error_for_bad_flag(testCase)
             magVals = ones(1,1000);
             SNR = 50;
             
             testCase.assertError(@() addNoise(magVals, SNR, 'BaDfLaG'), 'addNoise:unknownFlag');
        end

        function test_addNoise_throws_error_for_SNR_array(testCase)
             magVals = ones(1,1000);
             SNR = 1:50;
             
             testCase.assertError(@() addNoise(magVals, SNR), 'addNoise:snrWrongDims');
        end

        function test_addNoise_returns_only_positives_for_low_SNR_magnitude_data(testCase)
             magVals = ones(1,1000);
             SNR = 0.5;

             noisyMagVals = addNoise(magVals, SNR, 'magnitude');

             assertTrue(testCase, all(noisyMagVals>0));
         end
         
         
         function test_addNoise_returns_some_neg_vals_for_low_snr_gauss(testCase)
             import matlab.unittest.constraints.IsEqualTo;
             import matlab.unittest.constraints.AbsoluteTolerance;
             import matlab.unittest.constraints.RelativeTolerance;
             
             realVals = ones(1,1000);
             SNR = 2;

             noisyMagVals = addNoise(realVals, SNR, 'gaussian');
             
             noiseSTD = max(realVals)/SNR;

             testCase.assertThat(mean(noisyMagVals), IsEqualTo(mean(realVals), 'Within', AbsoluteTolerance(noiseSTD)));
             
             testCase.assertThat(std(noisyMagVals), IsEqualTo(noiseSTD, 'Within', RelativeTolerance(0.05)));
         end
         
         function test_addNoise_returns_approx_expected_means_and_std_for_gauss(testCase)
             magVals = ones(1,1000);
             SNR = 0.5;

             noisyMagVals = addNoise(magVals, SNR, 'gaussian');

             assertTrue(testCase, any(noisyMagVals<0));
         end
         
         function test_addNoise_returns_higher_noise_STD_for_MT_flag_case(testCase)
             magVals = 1;
             SNR = 50;

             for ii = 1:1000
                noisyMagVals(ii) = addNoise(magVals, SNR, 'MT');
             end

             noMT_NoiseSTD = max(magVals)/SNR;
             normalizedMT_STD = std(noisyMagVals);
             
             % Assert that there is an increase in noise SD of the
             % ratio-signal by at least 25%
             assertTrue(testCase, normalizedMT_STD > 1.25 * noMT_NoiseSTD);
         end
                 
    end
    
end