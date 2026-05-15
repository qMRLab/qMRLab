function standardize_novifast_test_data(dataPath, outputPath)
% Massage NOVIFAST example data to fit qMRLab structure
% Usage:
%   STANDARDIZE_NOVIFAST_TEST_DATA()
%   STANDARDIZE_NOVIFAST_TEST_DATA('/path/to/volume3DFSE.mat', '/path/to/demo_novifast.zip')
%
% This function is used to massage the example data that ships with the public NOVIFAST
% repository [1] into a structure compliant with qMRLab's guidelines [2].
%
% That is:
%   - Rename volume3DFSE.mat/im to VFAData.mat/VFAData
%   - Create a Mask (a cleaned-up version of NOVIFAST's default 5% hard-threshold)
%   - Write a Protocol.txt that can be imported with ProtLoad
%   - Generate FitResults and copy to FitResults/FitResults.mat
%
% References:
%   [1] Gabriel Ramos Llordén (2025). NOVIFAST: A fast algorithm for accurate and precise VFA MRI
%   (https://github.com/gabrll/MRIT1mappingNOVIFAST),
%   [2] https://github.com/qMRLab/qMRLab/wiki/Guideline:-Uploading-sample-data

if nargin < 1 || isempty(dataPath)
    dataPath = fullfile(fileparts(which('novifast_image')),'data','volume3DFSE.mat');
end
if nargin < 2 || isempty(outputPath)
    outputPath = fullfile(fileparts(mfilename('fullpath')),'demo_novifast.zip');
end

s = load(dataPath);

tmp = fullfile(tempdir(), 'novifast_data');
isfolder(tmp) || mkdir(tmp); %#ok<VUNUS>

files = struct();
files.VFAData = fullfile(tmp,'VFAData.mat');
files.Mask = fullfile(tmp,'Mask.mat');
files.Protocol = fullfile(tmp, 'Protocol.txt');
files.FitResults = fullfile(tmp, 'FitResults');

VFAData = s.im;
save(files.VFAData, 'VFAData');

Mask = calc_mask(VFAData, 0.05, 2, 10, 2, false);
save(files.Mask, 'Mask');

FlipAngle = s.alpha;
TR = repmat(9,numel(FlipAngle),1);

T = table(FlipAngle, TR, 'VariableNames', {'FlipAngle', 'TR'});
writetable(T, files.Protocol, 'delim', '\t');

% Generate reference FitResults
data = struct('VFAData', double(VFAData), 'Mask', double(Mask));
Model = novifast();
rng(123);
FitResults = FitData(data, Model, 0);
save(fitResultsPath, '-struct', 'FitResults');

mkdir(files.FitResults);
copyfile(fitResultsPath, fullfile(files.FitResults, 'FitResults.mat'));

zip(outputPath, struct2cell(files), tmp);

end

function mask = calc_mask(VFAData, Threshold, blurSigma, holeSize, shrink, plot)
% Estimate a mask using a simple threshold, with some smoothing/cleanup

    if nargin < 2 || isempty(Threshold), Threshold = 0.05; end
    if nargin < 3 || isempty(blurSigma), blurSigma = 2; end
    if nargin < 4 || isempty(holeSize), holeSize = 10; end
    if nargin < 4 || isempty(shrink), shrink = 2; end
    if nargin < 5 || isempty(plot), plot = true; end
    
    vol = max(VFAData,[],4);
    
    % 3D gaussian blur
    svol = imgaussfilt3(vol, blurSigma);
    
    % Threshold
    mask = svol > max(svol(:)) * Threshold;
    
    % Remove holes, and shrink
    se = strel('disk',holeSize);
    for j = 1:size(svol,3)
        mask(:,:,j) = imclose(mask(:,:,j),se);
        mask(:,:,j) = bwmorph(mask(:,:,j),'shrink', shrink);
    end

    if plot
        mtg = @(vol) montage(permute(vol,[1,2,4,3]), 'DisplayRange',[0,max(vol(:))]);
        close(findobj('Name','calc_mask'));
        figure('Name','calc_mask'); clf();
        mtg(mask.*vol);
        colormap(gca,[zeros(1,3);parula(256)]);
    end
end
