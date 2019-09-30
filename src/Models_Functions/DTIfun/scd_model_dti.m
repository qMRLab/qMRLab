function [D,L,fiberdirection] = scd_model_dti(data,scheme)

b0_index = scheme(:,4)<5e-6; % 5mT/m or less are considered as b=0
scheme = scheme(~b0_index,:);
data = data(~b0_index);
bvec = scheme(:,[1 2 3]);

%% Compute the transfert matrix of the system y=Hd --> d=(H'H)^-1*H'y
H=[bvec(:,1).^2 bvec(:,2).^2 bvec(:,3).^2 2*bvec(:,1).*bvec(:,2) 2*bvec(:,1).*bvec(:,3) 2*bvec(:,2).*bvec(:,3)];
K=(H'*H)\H';
d=-K*(log(squeeze(data))./scd_scheme_bvalue(scheme));
D=[d(1) d(4) d(5); d(4) d(2) d(6); d(5) d(6) d(3)];

% Eigenvectors of Diffusion tensor matrix
[V,L]=eig(D);
[L,I]=max(diag(L));
fiberdirection=V(:,I);


% % =========================================================================
% % Fractional Anisotropy
% % =========================================================================
% scd_scheme2bvecsbvals(scd_schemefile_read(schemefile), 'acq')
% if ~exist('DTI','dir'), mkdir('DTI'); end
% sct_unix(['export FSLOUTPUTTYPE=NIFTI; dtifit -k ' file ' -m ' mask ' -r acq.bvec -b acq.bvals -o DTI/' sct_tool_remove_extension(fname,0)]);