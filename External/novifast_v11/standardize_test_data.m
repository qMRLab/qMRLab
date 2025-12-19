function standardize_test_data(dataPath)
% Massage NOVIFAST example data to fit qMRLab structure
% Usage:
%   STANDARDIZE_TEST_DATA('/path/to/novifast/data/volume3DFSE.mat')
%
% Will take the VFA data shipped with [1] and generate a zip file in
% agreement with qMRLab guidelines[2].
%
% That is:
%   - Rename volume3DFSE.mat/im to VFAData.mat/VFAData
%   - Create a Mask (a cleaned-up version of NOVIFAST's default 5% hard-threshold)
%   - Write a Protocol.txt that can be imported with ProtLoad
%   - Include this script, as documentation of the changes.
%
% References:
%   [1] Gabriel Ramos Llordén (2025). NOVIFAST: A fast algorithm for accurate and precise VFA MRI 
%   (https://uk.mathworks.com/matlabcentral/fileexchange/67815-novifast-a-fast-algorithm-for-accurate-and-precise-vfa-mri), 
%   MATLAB Central File Exchange. Retrieved November 12, 2025. 
%   [2] https://github.com/qMRLab/qMRLab/wiki/Guideline:-Uploading-sample-data

if nargin < 1 || isempty(dataPath)
    dataPath = fullfile(fileparts(mfilename('fullpath')),'data','volume3DFSE.mat');
end
s = load(dataPath);

tmp = fullfile(tempdir(), 'novifast_data');
isfolder(tmp) || mkdir(tmp); %#ok<VUNUS>

files = struct();
files.code = [mfilename('fullpath'), '.m'];
files.VFAData = fullfile(tmp,'VFAData.mat');
files.Mask = fullfile(tmp,'Mask.mat');
files.Protocol = fullfile(tmp, 'Protocol.txt');

VFAData = s.im;
save(files.VFAData, 'VFAData');

Mask = calc_mask(VFAData, 0.05, 2, 10, 2, true);
save(files.Mask, 'Mask');

FlipAngle = s.alpha;
TR = repmat(9,numel(FlipAngle),1);

T = table(FlipAngle, TR, 'VariableNames', {'FlipAngle', 'TR'});
writetable(T, files.Protocol, 'delim', '\t');

zip(fullfile('novifast.zip'), struct2cell(files));

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
