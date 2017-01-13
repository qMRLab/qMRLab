function [xopt, Smodel, ModelOpt]  = qDiffusion(data,Prot,opt)

% Define parameters to fit
ModelOpt.ProtFormat = 'Gx   Gy   Gz   bvalue - GENERATE USING SCD_SCHEMEFILE_CREATE';
ModelOpt.xnames = { 'FA','L1','L2','L3'};
ModelOpt.x0           = [  0.7	0.5    0.5	 0.5];
ModelOpt.lb            = [  0       0       0       0];
ModelOpt.ub           = [ 1        3       3       3];

ModelOpt.buttons = {'model name',{'WatsonSHStickTortIsoV_B0','WatsonSHStickTortIsoVIsoDot_B0'}};
ModelOpt.data_fname = {'data'};
xopt=struct;
Smodel=[];


if nargin>0
    % convert units
    Prot(:,4)=Prot(:,4).*sqrt(sum(Prot(:,1:3).^2,2))*1e-3; % G mT/um
    Prot(:,1:3)=Prot(:,1:3)./repmat(sqrt(Prot(:,1).^2+Prot(:,2).^2+Prot(:,3).^2),1,3); Prot(isnan(Prot))=0;
    Prot(:,5) = Prot(:,5)*10^3; % DELTA ms
    Prot(:,6) = Prot(:,6)*10^3; % delta ms
    Prot(:,7) = Prot(:,7)*10^3; % TE ms
    gyro = 42.57; % kHz/mT
    Prot(:,8) = gyro*Prot(:,4).*Prot(:,6); % um-1

    % fit
    D=scd_model_dti(data./scd_preproc_getIb0(data,Prot),Prot);
    [~,L]=eig(D); L = sort(diag(L),'descend');
    xopt.L1=L(1);
    xopt.L2=L(2);
    xopt.L3=L(3);
    
    % compute metrics
    L_mean = sum(L)/3;
    xopt.FA = sqrt(3/2)*sqrt(sum((L-L_mean).^2))/sqrt(sum(L.^2));
    
    % Compute Smodel
    bvec=Prot(:,[1 2 3]);
    Smodel = scd_preproc_getIb0(data,Prot).*exp(-scd_scheme_bvalue(Prot).*diag(bvec*D*bvec'));
end

