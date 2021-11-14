function [MTsat_b1corr] = sample_code_correct_MTsat(data,MTparams,PDparams,T1params,fitValues)
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
    disp('No <fitValues.mat> file found, run simulation first')
end
fitValues = fitValues.fitValues; % may or maynot need this line depending on how it saves

hfa = data.T1w;
lfa = data.PDw;
mtw = data.MTw;

%% Load B1 map and set up b1 matrices

% B1 nominal and measured
b1_rms = 2.36; % value in microTesla. Nominal value for the MTsat pulses  % -> USER DEFINED

% load B1 map
b1 = data.B1map/100;

% filter the b1 map if you wish. 
%b1 = imgaussfilt3(b1,1);

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
% hfa_proc= unring3D(all_PCAcorr(:,:,:,1),3);
% lfa_proc= unring3D(all_PCAcorr(:,:,:,2),3);
% mtw_proc = unring3D(all_PCAcorr(:,:,:,3) ,3);
% 
% % Use the code below to see if you got the right value 
% figure; imshow3Dfull(mtw_proc, [150 600])
% figure; imshow3Dfull(all_PCAcorr(:,:,:,3), [150 600])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Generate a brain mask to remove background
mask = zeros(size(lfa)); 
mask (lfa >175) = 1;  % check your threshold here, data dependent. You could also load a mask made externally instead. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Begin MTsat calculation 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Calculate A0 and R1
low_flip_angle = PDparams(1);    % flip angle in degrees % -> USER DEFINED
high_flip_angle = T1params(1);  % flip angle in degrees % -> USER DEFINED
TR = PDparams(2)*1000;               % repetition time of the GRE kernel in milliseconds % -> USER DEFINED

a1 = low_flip_angle*pi/180 .* b1;
a2 = high_flip_angle*pi/180 .* b1; 

R1 = 0.5 .* (hfa.*a2./ TR - lfa.*a1./TR) ./ (lfa./(a1) - hfa./(a2));
R1 = R1.*mask;
T1 = 1/R1  .* mask;

App = lfa .* hfa .* (TR .* a2./a1 - TR.* a1./a2) ./ (hfa.* TR .*a2 - lfa.* TR .*a1);
App = App .* mask;

%% Generate MTsat maps for the MTw images. 
% Inital Parameters
readout_flip = MTparams(1); % flip angle used in the MTw image, in degrees % -> USER DEFINED
TR = MTparams(2); % -> USER DEFINED

% calculate maps as per Helms et al 2008. 
a_MTw_r = readout_flip /180 *pi;
MTsat = (App.* (a_MTw_r*b1)./ mtw_proc - 1) .* (R1) .* TR - ((a_MTw_r*b1).^2)/2;

% check result
figure; imshow3Dfull(MTsat, [0 0.03],jet)

%fix limits for background
MTsat(MTsat<0) = 0;

%% Generate MTsat correction factor maps.
R1_s = R1* 1000; % convert from 1/ms to 1/s

%% Generate MTsat correction factor map. 
CF_MTsat = MTsat_B1corr_factor_map(b1_gauss, R1_s, b1_rms,fitValues);

%% Correct the maps
MTsat_b1corr  = MTsat  .* (1+ CF_MTsat)  .* mask;

% display the corrected and uncorrected for comparison
figure; imshow3Dfull(MTsat, [0 0.03],jet); 
figure; imshow3Dfull(MTsat_b1corr, [0 0.03],jet)

end