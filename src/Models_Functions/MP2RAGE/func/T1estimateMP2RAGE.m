function [T1map, R1map]=T1estimateMP2RAGE(MP2RAGEnii,MP2RAGE,varargin)
% usage
% [T1map, R1map]=T1estimateMP2RAGE(MP2RAGEnii,MP2RAGE,varargin)
% MP2RAGEnii is the nii structure resulting from loading the MP2RAGE
% with load_nii or load_untouch_nii
% MP2RAGE is a structure containing all the relevant sequence
% information as delailed below
%
%     MP2RAGE.B0=7;           % in Tesla
%     MP2RAGE.TR=6;           % MP2RAGE TR in seconds
%     MP2RAGE.TRFLASH=6.7e-3; % TR of the GRE readout
%     MP2RAGE.TIs=[800e-3 2700e-3];% inversion times - time between middle of refocusing pulse and excitatoin of the k-space center encoding
%     MP2RAGE.NZslices=[40 80];% Slices Per Slab * [PartialFourierInSlice-0.5  0.5]
%     MP2RAGE.FlipDegrees=[4 5];% Flip angle of the two readouts in degrees
%
%
% additionally the inversion efficiency of the adiabatic inversion can be
% set as a last optional variable. Ideally it should be 1.
% In the first implementation of the MP2RAGE the inversino efficiency was
% measured to be ~0.96
%
% script to convert MP2RAGE images into T1 map estimates as suggested in:
% MP2RAGE, a self bias-field corrected sequence for improved segmentation and T 1-mapping at high field
% JP Marques, T Kober, G Krueger, W van der Zwaag, PF Van de Moortele, R.
% Gruetter, Neuroimage 49 (2), 1271-1281, 2010
%
%


if nargin==3
    invEFF=varargin{1};
else
    invEFF=0.96;
end;

[Intensity T1vector]=MP2RAGE_lookuptable(2,MP2RAGE.TR,MP2RAGE.TIs,MP2RAGE.FlipDegrees,MP2RAGE.NZslices,MP2RAGE.TRFLASH,'normal',invEFF);

% checks if it is a standard MP2RAGE image, from -0.5 to 0.5, or if it is a
% DICOM which should have been scaled from 0 to 4095

if max(abs(MP2RAGEnii.img(:)))>1
    T1=interp1(Intensity,T1vector,-0.5+1/4095*double(MP2RAGEnii.img(:)));
else
    T1=interp1(Intensity,T1vector,MP2RAGEnii.img(:));
end;
T1(isnan(T1))=0;

% copies the header from the MP2RAGEnii
T1map=MP2RAGEnii;
R1map=MP2RAGEnii;
% and puts there the T1 estimation
T1map.img=reshape(T1,size(MP2RAGEnii.img));
R1map.img=1./T1map.img;
R1map.img(isnan(R1map.img))=0;

