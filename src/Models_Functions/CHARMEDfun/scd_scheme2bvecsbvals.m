function [bvals, bvec, f_bvec, f_bvals] = scd_scheme2bvecsbvals(scheme, acq_basename)
% scd_scheme2bvecs(scheme, acq_basename)
% EXAMPLE:  scheme = scd_schemefile_read(ls('*.scheme')); 
%           [bvals, bvec] = scd_scheme2bvecsbvals(scheme);


bvec = scheme(:,1:3);
gyro = 42.57; % kHz/mT
bvals = (2*pi*gyro*scheme(:,4).*scheme(:,6).*10^(3)).^2.*(scheme(:,5)-scheme(:,6)/3)*10^(-3);

if nargin>1
f_bvec=[acq_basename '.bvec.txt'];
f_bvals=[acq_basename '.bvals.txt'];
fid_bvec_tot = fopen(f_bvec,'w');
fid_bvals_tot = fopen(f_bvals,'w');

for i=1:size(scheme,1)
        % write bvecs
        fprintf(fid_bvec_tot, '%f %f %f\n',bvec(i,:));
        % write bvals
        fprintf(fid_bvals_tot, '%f\n',bvals(i));
        
end


fclose all;


end

    
