function [MTsat_b1corr, MTsatuncor,R1,R1uncor] = sample_code_correct_MTsat(data,MTparams,PDparams,T1params,fitValues,obj)
%% Sample code to correct B1+ inhomogeneity in MTsat maps 
% Please see the README file to make sure you have the necessary MATLAB
% packages to run this code.

% This script is to analyze MTw images obtained at different B1 pulse
% amplitudes applied for the MT saturation pulses. 

% currently set up to be run section by section so that you can view the
% results/ check data quality/ troubleshoot. To run faster, comment out lines used to
% display the images.

% code that can be used to load/export MRI data is here: https://github.com/ulrikls/niak
% image view code is a modified version of https://www.mathworks.com/matlabcentral/fileexchange/47463-imshow3dfull

%% load images
if ~exist('fitValues','var')
    disp('No <fitValues> found, run simulation first or check DataPath')
end
fitValues = fitValues.fitValues; % may or maynot need this line depending on how it saves

hfa = data.T1w;
lfa = data.PDw;
mtw = data.MTw;

%% Load B1 map and set up b1 matrices

% B1 nominal and measured
% b1_rms = 2.36; % value in microTesla. Nominal value for the MTsat pulses  % -> USER DEFINED
b1_rms = obj.options.CorrelateM0bappVSR1_b1rms;

% load B1 map
b1 = data.B1map;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% % include any preprocessing steps here such as MP-PCA denoising, and
% % unringing of GRE images. Not needed for this analysis. Each of the below
% % functions can be optimized for your dataset. 
% %% denoise (code here https://github.com/sunenj/MP-PCA-Denoising)  % -> USER DEFINED OPTION
% % works better with the more images you have. 
% img_dn = cat(4,hfa,lfa,mtw);
% all_PCAcorr = MPdenoising(img_dn);
% 
% %% unring the images ( code here https://github.com/josephdviviano/unring)
% % depending on how your images were collected/loaded, the final number in
% % the line could be a 1,2 or 3. 
% hfa = unring3D(all_PCAcorr(:,:,:,1),3);
% lfa = unring3D(all_PCAcorr(:,:,:,2),3);
% mtw = unring3D(all_PCAcorr(:,:,:,3) ,3);
% 
% % Use the code below to see if you got the right value 
% figure; imshow3Dfull(mtw, [150 600])
% figure; imshow3Dfull(all_PCAcorr(:,:,:,3), [150 600])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Brain mask to remove background (optional)
if isfield(data,'Mask') && (~isempty(data.Mask))
    mask = data.Mask;
else
    mask = ones(size(lfa));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Begin MTsat calculation 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Calculate A0 and R1
low_flip_angle = PDparams(1);    % flip angle in degrees % -> USER DEFINED
high_flip_angle = T1params(1);  % flip angle in degrees % -> USER DEFINED
TR1 = PDparams(2)*1000;         % low flip angle repetition time of the GRE kernel in milliseconds -> USER DEFINED
TR2 = T1params(2)*1000;         % high flip angle repetition time of the GRE kernel in milliseconds -> USER DEFINED
%TR = PDparams(2)*1000;               % repetition time of the GRE kernel in milliseconds % -> USER DEFINED

Inds = find(lfa & hfa & mtw);

a1 = low_flip_angle*pi/180 .* b1;
a2 = high_flip_angle*pi/180 .* b1;

% New code Aug 4, 2021 CR for two TR's
R1 = zeros(size(mtw));
App = zeros(size(mtw));
R1(Inds) = 0.5 .* (hfa(Inds).*a2(Inds)./ TR2 - lfa(Inds).*a1(Inds)./TR1) ./ (lfa(Inds)./(a1(Inds)) - hfa(Inds)./(a2(Inds)));
App(Inds) = lfa(Inds) .* hfa(Inds) .* (TR1 .* a2(Inds)./a1(Inds) - TR2.* a1(Inds)./a2(Inds)) ./ (hfa(Inds).* TR1 .*a2(Inds) - lfa(Inds).* TR2 .*a1(Inds));

% Uncorrected R1
a1uncor = low_flip_angle*pi/180 .* ones(size(mtw));
a2uncor = high_flip_angle*pi/180 .* ones(size(mtw));
R1uncor = zeros(size(mtw));
R1uncor(Inds) = 0.5 .* (hfa(Inds).*a2uncor(Inds)./ TR2 - lfa(Inds).*a1uncor(Inds)./TR1) ./ (lfa(Inds)./(a1uncor(Inds)) - hfa(Inds)./(a2uncor(Inds)));

% Old code for single TR only
%R1 = 0.5 .* (hfa.*a2./ TR - lfa.*a1./TR) ./ (lfa./(a1) - hfa./(a2));
%App = lfa .* hfa .* (TR .* a2./a1 - TR.* a1./a2) ./ (hfa.* TR .*a2 - lfa.* TR .*a1);

R1 = R1.*mask;
R1uncor = R1uncor.*mask;
App = App.*mask;

%% Generate MTsat maps for the MTw images. 
% Inital Parameters
readout_flip = MTparams(1); % flip angle used in the MTw image, in degrees % -> USER DEFINED
TR = MTparams(2)*1000; % -> USER DEFINED
a_MTw_r = readout_flip*pi/180 .* b1;

% calculate maps as per Helms et al 2008. Note: b1 (excitation pulse) is included here for flip angle
MTsat_b1exc_cor = zeros(size(mtw));
MTsat_b1exc_cor(Inds) = (App(Inds).* (a_MTw_r(Inds))./ mtw(Inds) - ones(size(mtw(Inds)))) .* (R1(Inds)) .* TR - ((a_MTw_r(Inds)).^2)/2;

% calculate maps as per Helms et al 2008. Note: no correction at all
a_MTw_r_uncor = readout_flip.*pi/180 .* ones(size(mtw));
MTsatuncor = zeros(size(mtw));
MTsatuncor(Inds) = (App(Inds).* (a_MTw_r_uncor(Inds))./ mtw(Inds) - ones(size(mtw(Inds)))) .* (R1(Inds)) .* TR - ((a_MTw_r_uncor(Inds)).^2)/2;

%fix limits for background
MTsat_b1exc_cor(MTsat_b1exc_cor<0) = 0;
MTsatuncor(MTsatuncor<0) = 0;

%% Generate MTsat correction factor maps.
R1_s = R1*1000; % convert from 1/ms to 1/s

%% Generate MTsat correction factor map. 
CF_MTsat = MTsat_B1corr_factor_map(b1, R1_s, b1_rms,fitValues);

%% Correct the maps
new_mask = zeros(size(mtw));
new_mask(Inds) = 1;
MTsat_b1corr  = MTsat_b1exc_cor  .* (1+ CF_MTsat)  .* new_mask;

% display the corrected and uncorrected for comparison
figure; imshow3Dfull(MTsatuncor, [0 0.03],jet);
figure; imshow3Dfull(MTsat_b1exc_cor, [0 0.03],jet);
figure; imshow3Dfull(MTsat_b1corr, [0 0.03],jet)

end