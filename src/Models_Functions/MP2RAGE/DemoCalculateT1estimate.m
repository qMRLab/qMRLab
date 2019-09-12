% script to convert MP2RAGE images into T1 (R1) map estimates as suggested in:
% MP2RAGE, a self bias-field corrected sequence for improved segmentation and T 1-mapping at high field
% JP Marques, T Kober, G Krueger, W van der Zwaag, PF Van de Moortele, R.
% Gruetter, Neuroimage 49 (2), 1271-1281, 2010
%
 
% 
%
addpath(genpath('.'))
 
    
%% MP2RAGE protocol info and loading the MP2RAGE dataset 
    
    MP2RAGE.B0=7;           % in Tesla
    MP2RAGE.TR=6;           % MP2RAGE TR in seconds 
    MP2RAGE.TRFLASH=6.7e-3; % TR of the GRE readout
    MP2RAGE.TIs=[800e-3 2700e-3];% inversion times - time between middle of refocusing pulse and excitatoin of the k-space center encoding
    MP2RAGE.NZslices=[35 72];% Slices Per Slab * [PartialFourierInSlice-0.5  0.5]
    MP2RAGE.FlipDegrees=[4 5];% Flip angle of the two readouts in degrees
    MP2RAGE.filename='MP2RAGE_UNI.nii' % file
    
    
    % check the properties of this MP2RAGE protocol... this happens to be a
    % very B1 insensitive protocol

    plotMP2RAGEproperties(MP2RAGE)

    % load the MP2RAGE data - it can be either the SIEMENS one scaled from
    % 0 4095 or the standard -0.5 to 0.5
    MP2RAGEimg=load_untouch_nii(MP2RAGE.filename);
    
    [T1map, R1map]=T1estimateMP2RAGE(MP2RAGEimg,MP2RAGE,0.96);
    
