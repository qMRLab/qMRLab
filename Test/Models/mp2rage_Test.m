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

    end
end
