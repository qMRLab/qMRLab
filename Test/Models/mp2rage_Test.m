classdef (TestTags = {'Unit'}) mp2rage_Test < matlab.unittest.TestCase
    % Covers how mp2rage decides which inputs it was given. Which branch is
    % taken depends only on which fields are empty, so these tests need no
    % example dataset and run in milliseconds.

    methods (Static, Access = private)
        function v = volume(value)
            % Smallest volume the fit will accept.
            v = repmat(value, [2 2 2]);
        end
    end

    methods (Access = private)
        function FitResult = quietFit(~, data)
            % mp2rage.fit is chatty; keep the test output readable.
            Model = mp2rage();
            evalc('FitResult = Model.fit(data);');
        end
    end

    methods (Test)

        function test_two_magnitudes_use_the_magnitude_only_combination(testCase)
            %% Prep
            inv1 = 100; inv2 = 60;
            data = struct('INV1mag', testCase.volume(inv1), ...
                          'INV2mag', testCase.volume(inv2));

            %% Fit
            FitResult = testCase.quietFit(data);

            %% Verify
            expected = (inv1*inv2/(inv1^2 + inv2^2))*4095 + 2048;
            testCase.verifyEqual(FitResult.MP2RAGE(1,1,1), expected, 'RelTol', 1e-10, ...
                'Magnitude-only data should be combined as INV1*INV2/(INV1^2+INV2^2).');
        end

        function test_insufficient_data_is_rejected_with_the_documented_error(testCase)
            %% Prep
            % A single inversion image is never enough to fit T1.
            data = struct('INV1mag', testCase.volume(100));

            %% Fit & Verify
            try
                testCase.quietFit(data);
                testCase.verifyFail('fit should have rejected a single inversion image.');
            catch ME
                testCase.verifySubstring(ME.message, 'Required data is not provided', ...
                    'Insufficient input should raise the qMRLab guard, not fail deeper in the fit.');
            end
        end

        function test_supplied_UNI_is_not_silently_discarded(testCase)
            %% Prep
            % Magnitudes plus a UNI image. Whatever mp2rage does here, it must
            % not quietly throw the UNI away and return the magnitude-only result.
            inv1 = 100; inv2 = 60;
            magnitudeOnly = (inv1*inv2/(inv1^2 + inv2^2))*4095 + 2048;
            data = struct('INV1mag',  testCase.volume(inv1), ...
                          'INV2mag',  testCase.volume(inv2), ...
                          'MP2RAGE',  testCase.volume(2500));

            %% Fit
            rejected = false;
            try
                FitResult = testCase.quietFit(data);
            catch
                rejected = true;   % refusing the combination is acceptable
            end

            %% Verify
            if ~rejected
                testCase.verifyNotEqual(FitResult.MP2RAGE(1,1,1), magnitudeOnly, ...
                    'A supplied UNI image was ignored in favour of the magnitude-only combination.');
            end
        end

        function test_equal_number_of_shots_are_used_as_given(testCase)
            % Issue #547. Without partial Fourier in the slice direction the
            % shots before and after the k-space centre are equal: 176 slices
            % per slab gives [88; 88]. Those values must reach the signal model
            % unchanged, as in Marques's original code.

            %% Prep
            % UNI value for T1 = 1.5 s, simulated independently with José
            % Marques's MP2RAGE-related-scripts (MP2RAGE_lookuptable.m, master
            % 7a4ba42) for the protocol pinned below, with NZslices = [88 88].
            trueT1 = 1.5;
            uni = 1723.4903052275;

            Model = mp2rage();
            Model.Prot.RepetitionTimes.Mat = [6; 6.7e-3];
            Model.Prot.Timing.Mat = [0.8; 2.7];
            Model.Prot.Sequence.Mat = [4; 5];
            Model.Prot.NumberOfShots.Mat = [88; 88];
            Model.options.Invefficiency = 0.96;
            data = struct('MP2RAGE', testCase.volume(uni));

            %% Fit
            evalc('FitResult = Model.fit(data);');

            %% Verify
            testCase.verifyEqual(FitResult.T1(1,1,1), trueT1, 'RelTol', 1e-3, ...
                'Equal Pre/Post NumberOfShots were not used as given (issue #547).');
        end

    end
end
