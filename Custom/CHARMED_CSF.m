function [xopt, Smodel, ModelOpt]  = CHARMED_CSF(data,Prot,opt)

% Define parameters to fit
ModelOpt.ProtFormat = 'Gx   Gy   Gz   |G|  Delta  delta  TE - GENERATE USING SCD_SCHEMEFILE_CREATE';
ModelOpt.xnames = {'fh','Dh','diameter_mean','fcsf'};
ModelOpt.st           = [0.6     0.7        6       0.2          ];
ModelOpt.lb            = [0       0.3        3          0               ];
ModelOpt.ub           = [1       3         10         1                ];

ModelOpt.buttons = {'Dcsf',3,'Dr',1.4,'noisepervoxel',true,'sigma_noise',10};

xopt=struct;
Smodel=[];
% Don't fit if no input
if nargin==0, return; end

    A = zeros([size(opt.st,1) 1])'; A(3) = -0.95; A(4) = 1; b =-0.49;
    
    % convert units
    Prot(:,4)=Prot(:,4).*sqrt(sum(Prot(:,1:3).^2,2))*1e-3; % G mT/um
    Prot(:,1:3)=Prot(:,1:3)./repmat(sqrt(Prot(:,1).^2+Prot(:,2).^2+Prot(:,3).^2),1,3); Prot(isnan(Prot))=0;
    Prot(:,5) = Prot(:,5)*10^3; % DELTA ms
    Prot(:,6) = Prot(:,6)*10^3; % delta ms
    Prot(:,7) = Prot(:,7)*10^3; % TE ms
    gyro = 42.57; % kHz/mT
    Prot(:,8) = gyro*Prot(:,4).*Prot(:,6); % um-1
    list=unique(Prot(:,7:-1:5),'rows');
    nnn = size(list,1);
    for j = 1 : nnn
        for i = 1 : size(Prot,1)
            if  Prot(i,7:-1:5) == list(j,:)
                Prot(i,9) = j;
            end
        end
    end
    
    opt.scheme=Prot;
    opt.data=data;
    % fit
    
    opt.S0 = scd_preproc_getIb0(data,Prot);
    
    if isfield(opt,'noisepervoxel'),
        scheme=Prot;
        scheme(scheme(:,4)==0,[5 6])=0;
        % find images that where repeated
        [~,c,ind]=consolidator(scheme(:,1:8),[],'count');
        cmax = max(c); % find images repeated more than 5 times (for relevant STD)
        if cmax<5, error('<strong>Your dataset doesn''t have 5 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise. use scd_noise_fit_histo_nii.m instead to estimate the noise STD.</strong>'); end
        
        repeated_measured = find(c==cmax);
        for irep=1:length(repeated_measured)
            STDs(irep)=std(data(ind==repeated_measured(irep)));
        end
        opt.sigma_noise = mean(STDs);
    end
    
    % define model
    fixedparam=opt.fx;
    modelfun = @(x,scheme) CHARMEDGPD(addfixparameters(opt.st,x,fixedparam),Prot,opt); % see: >> doc lsqcurvefit
    
    %% FITTING
    % initiate with Gaussian noise assumption --> more stable fitting
    [xopt, residue] = lsqcurvefit(modelfun,opt.st(~fixedparam),Prot,double(data),double(opt.lb(~fixedparam)),double(opt.ub(~fixedparam)),optimoptions('lsqcurvefit','MaxIter',20,'display','off'));
    opt.st(~fixedparam)=xopt; xopt = opt.st;
    
    % use Rician noise and fix fix b=0
    fixedparam(6:end)=true;
    modelfun = @(x,scheme) CHARMEDGPD(addfixparameters(opt.st,x,fixedparam),Prot,opt); % see: >> doc lsqcurvefit
    [xopt, residue]=fmincon(@(x) double(-2*sum(scd_model_likelihood_rician(data,max(eps,modelfun(x)), opt.sigma_noise))), double(opt.st(~fixedparam)), [], [], [],[],double(opt.lb(~fixedparam)),double(opt.ub(~fixedparam)),[],optimoptions('fmincon','MaxIter',20,'display','off','DiffMinChange',0.03));
    opt.st(~fixedparam)=xopt; xopt = opt.st;
    
    %% OUTPUTS
    Smodel=CHARMEDGPD(xopt,Prot,opt);
    if isfield(opt,'plot') && opt.plot
        scd_display_fits(data,Smodel,Prot); 
    end
    xopt(end+1) = residue;
    opt.names{end+1}='residue';
    
    xopt = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),opt.names,1);
    

function x0 = addfixparameters(x0,x,fixedparam)
x0(~fixedparam)=x;

function data_model=CHARMEDGPD(x,Prot,opt)
% S0
S0 = opt.S0;
x(5)=x(4);
% CHARMED
data_model = S0.*scd_model_CHARMED(x,opt);

% if opt.plotfit && randn>1
%     figure(3), scd_display_fits(opt.data,data_model,Prot); drawnow
% end
