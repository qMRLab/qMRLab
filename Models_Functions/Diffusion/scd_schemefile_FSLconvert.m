function scd_schemefile_FSLconvert(bvalfile, bvecfile, Gmax, T180, schemefile)
%
% scd_schemefile_FSLconvert(bvalfile, bvecfile, Gmax, T180, schemefile)
% scd_schemefile_FSLconvert('bvals.txt', 'bvecs.txt', 80, 5.8, 'scheme.txt')
%
% This function assumes that TE is minimized for the maximal bvalue
% (diffusion gradients duration are maximized).
%
% INPUTS:
%   bvalfile: FSL bval text file (output of dcm2nii or dicm2nii)
%   bvecfile: FSL bvec text file (output of dcm2nii or dicm2nii)
%   Gmax: maximal gradient strength of the MRI system used in mT/m. example: Gmax=80.
%   T180: duration of the refocusing pulse + gradient rising time. In ms.
%         example:
%         T180 = 5ms + Gmax/Slewrate
%         T180 = 5ms + (80 mT/m) / (100 mT/m/ms)
%         T180 = 5.8;
%   schemefile: name of the output scheme file (e.g. scheme.txt)
%
% Inspired from FSL2Protocol.m from NODDI toolbox (Original author: Gary Hui Zhang)
% author: Tanguy Duval

% load bval
bval = txt2mat(bvalfile);
bval = bval(:);

% load bvec
bvecs = txt2mat(bvecfile);

disp(['\nCheck if bvecs is written by lines or by columns...'])
if size(bvecs,1)==3 && size(bvecs,2)~=3
    disp(['\nbvecs seems to be written in columns, transposing it...'])
    bvecs=bvecs';
else
	disp(['.. OK! written by lines'])
end

% maximum b-value in the s/mm^2 unit
maxB = max(bval);

% Fill scheme
scheme(:,1:3)=bvecs;
% set smalldel and delta and G
GAMMA = 2.675987E8;
tmp = roots([2/3 T180 0 -maxB*10^6/(GAMMA^2*(Gmax*1e-3)^2)*1e9]);
tmp = tmp(tmp>0); tmp = round(min(tmp)*10)/10;

scheme(:,6) = tmp; % delta
scheme(:,5) = tmp + T180; % DELTA
scheme(:,4) = sqrt(bval/maxB)*Gmax*1e-6;
scheme(:,7) = 2*tmp + T180 + 20; % Approximate value assuming readout time of 20ms. TE is not used in models with single TE.

scd_schemefile_write(scheme,schemefile);