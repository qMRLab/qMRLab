classdef (TestTags = {'Unit'}) LoadComplex_Test < matlab.unittest.TestCase

    properties (TestParameter)
        validPairs = cell2struct({
                {'real.nii','imaginary.nii'};
                {'foo_REAL.nii', 'foo_phase.nii'};
                {'MAGNITUDE.nii.gz','PHASE.nii.gz'};
                {'phaseData.ext', 'IMAGINARYdata.ext'}
            },{'real_imag','real_phase','mag_phase','phase_imag'})

        ambiguousPairs = cell2struct({
                {'real.ext', 'MAGNITUDE.ext'};
                {'magnitude_image.ext', 'imaginary_image.ext'}
            },{'mag_real','mag_imag'})

        badArguments = {
                {'real'};
                {'real.ext'}
                {'imaginary', 'imaginary.ext'};
                {'real', 'imaginary', 'magnitude'};
                {'foo','bar'};
                {'foo','real','bar','imaginary'};
            }

        badMatches = {
                {'real_A.ext','real_B.ext'};
                {'real.ext', 'imaginary.ext', 'phase.ext'};
                {'real_imaginary.ext','phase.ext'};
                {'real_imaginary.ext','imaginary_real.ext'};
            }
    end

    methods(Static)
        function [data, hdr] = DummyRead(dummyFile)
        % Mock Image Loader - returns components of DummyData
        %   based on file name

            d = LoadComplex_Test.DummyData();
            if contains(dummyFile,'real','IgnoreCase',1)
                data = real(d);
            elseif contains(dummyFile,'imaginary','IgnoreCase',1)
                data = imag(d);
            elseif contains(dummyFile,'magnitude','IgnoreCase',1)
                data = abs(d);
            elseif contains(dummyFile,'phase','IgnoreCase',1)
                data = angle(d);

                % simulate "scaled" phase data
                s = regexpi(dummyFile,'(?<=phase)(\d+)', 'match');
                if ~isempty(s)
                    data = data * str2double(s{1})/pi;
                end
            else
                error('DummyRead:name', 'File not found')
            end
            hdr = struct('file', dummyFile, 'size', size(data));
        end
        function data = DummyData()
        % A constant array of complex data
            rng(42)
            gen = @() randi([-10, 10], 3, 4);
            data = gen() + 1i*gen();
        end
    end

    methods
        function fnames = touchDummyFiles(testCase, varargin)
        % ff = testCase.touchDummyFiles(A, B, ...) - will create empty
        %   files in a temporary directory and return a cell array
        %   with their full path. Files are meant to be "read" with
        %   DummyRead, i.e. their mock content depends only on their name.
        %
        %   Argument names without extension will NOT create a file

            import matlab.unittest.fixtures.TemporaryFolderFixture
            fx = testCase.applyFixture(TemporaryFolderFixture);

            fnames = cell(size(varargin));
            for j = 1:numel(varargin)
                if ~contains(varargin{j}, '.'), continue; end
                fnames{j} = fullfile(fx.Folder, varargin{j});
                fid = fopen(fnames{j}, 'w');
                fclose(fid);
            end
        end
    end

    methods (Test)
        function testLoadExplicit(testCase)
        % LOADCOMPLEX('real',FILEA,'imaginary',FILEB)
            ff = testCase.touchDummyFiles('real.nii', 'imaginary.nii');
            [data, hdr] = LoadComplex('real',ff{1}, 'imaginary', ff{2},...
                                      @LoadComplex_Test.DummyRead);
            testCase.verifyEqual(data, LoadComplex_Test.DummyData());

            expHdr = struct('file', cell2struct(ff',{'real','imaginary'}), 'size', size(data));
            testCase.verifyEqual(hdr, expHdr)
        end

        function testLoadByName(testCase, validPairs)
        % LOADCOMPLEX('file_KEYA.ext','file_KEYB.ext')
            ff = testCase.touchDummyFiles(validPairs{:});
            [data, ~] = LoadComplex(ff{:}, @LoadComplex_Test.DummyRead);
            d = LoadComplex_Test.DummyData();
            testCase.verifyEqual(data, d, 'AbsTol', 1e-12);
        end

        function testLoadByPattern(testCase)
        % LOADCOMPLEX('file_*.ext')
            ff = testCase.touchDummyFiles('real.nii', 'imaginary.nii', 'foo.bar');
            pat = fullfile(fileparts(ff{1}), '*.nii');
            [data, ~] = LoadComplex(pat, @LoadComplex_Test.DummyRead);
            d = LoadComplex_Test.DummyData();
            testCase.verifyEqual(data, d);
        end

        function testLoadAmbiguous(testCase, ambiguousPairs)
        % magnitude + phase / magnitude + imaginary
            ff = testCase.touchDummyFiles(ambiguousPairs{:});
            fn = @() LoadComplex(ff{:}, @LoadComplex_Test.DummyRead);

            [data, ~] = verifyWarning(testCase, fn, 'qMRLab:LoadComplex:ambiguous');
            d = abs(LoadComplex_Test.DummyData());
            testCase.verifyEqual(data, d);
        end

        function testBadArguments(testCase, badArguments)
            ff = testCase.touchDummyFiles(badArguments{:});
            fn = @() LoadComplex(ff{:});
            verifyError(testCase, fn, 'qMRLab:LoadComplex:args');
        end

        function testBadMatches(testCase, badMatches)
            ff = testCase.touchDummyFiles(badMatches{:});
            pat = fullfile(fileparts(ff{1}), '*.ext');
            fn = @() LoadComplex(pat);
            verifyError(testCase, fn, 'qMRLab:LoadComplex:match');
        end

        function testLoadUnsupported(testCase)
            ff = testCase.touchDummyFiles('real.nii', 'foo.txt');
            fn = @() LoadComplex('real',ff{1}, 'imaginary', ff{2}, @LoadComplex_Test.DummyRead);
            verifyError(testCase, fn, 'DummyRead:name');
        end

        function testPhaseScaling(testCase)
        % Test that phase data gets rescaled to -pi/pi
            ff = testCase.touchDummyFiles('magnitude.nii', 'phase10.nii');
            fn = @() LoadComplex(ff{:}, @LoadComplex_Test.DummyRead);
            [data, ~] = verifyWarning(testCase, fn, 'qMRLab:LoadComplex:phasebounds');
            d = LoadComplex_Test.DummyData();
            testCase.verifyEqual(data, d, 'AbsTol', 1e-12);
        end
    end
end
