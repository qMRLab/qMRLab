function [xopt, Smodel, ModelOpt]  = CHARMED(data,Prot,opt)

% Define parameters to fit
ModelOpt.ProtFormat = 'Gx   Gy   Gz   |G|  Delta  delta  TE - GENERATE USING SCD_SCHEMEFILE_CREATE';
ModelOpt.xnames = {'fh','Dh','diameter_mean','diameter_STD','fcsf'};
ModelOpt.st           = [0.6     0.7        6        0.5       0.2      0.1         0.1           ones(1,10)       ];
ModelOpt.lb            = [0       0.3        3        0.1      0        0         0              0.7*ones(1,10)       ];
ModelOpt.ub           = [1       3         10         2        1     90        90              1.3*ones(1,10)       ];

ModelOpt.buttons = {'Dcsf',3,'sigma_noise',10,'plotfit',true};

xopt=struct;
Smodel=[];


if nargin>0
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
        cmopt = mopt(c); % find images repeated more than 5 times (for relevant STD)
        if cmopt<5, error('<strong>Your dataset doesn''t have 5 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise. use scd_noise_fit_histo_nii.m instead to estimate the noise STD.</strong>'); end
        
        repeated_measured = find(c==cmopt);
        for irep=1:length(repeated_measured)
            STDs(irep)=std(data(ind==repeated_measured(irep)));
        end
        opt.sigma_noise = mean(STDs);
    end
    
    % define model
    fixedparam=cellfun(@isempty,opt.names);
    modelfun = @(x,scheme) CHARMEDGPD(addfixparameters(opt.st,x,fixedparam),Prot,opt); % see: >> doc lsqcurvefit
    
    % % find the best initialization
    % opt.corrobj=1;
    % for istart = 1:size(opt.st,2), cost(istart) = objectivefunc(opt.st(:,istart),opt); end; [~,I]=min(cost); opt.st = opt.st(:,I);
    
    %% FITTING
    % initiate with Gaussian noise assumption --> more stable fitting
    [xopt, residue] = lsqcurvefit(modelfun,opt.st(~fixedparam),Prot,double(data),double(opt.lb(~fixedparam)),double(opt.ub(~fixedparam)),optimoptions('lsqcurvefit','MaxIter',20,'display','off'));
    opt.st(~fixedparam)=xopt; xopt = opt.st;
    
    % use Rician noise and fix fix b=0
    fixedparam(6:end)=true;
    modelfun = @(x,scheme) CHARMEDGPD(addfixparameters(opt.st,x,fixedparam),Prot,opt); % see: >> doc lsqcurvefit
    [xopt, residue]=fmincon(@(x) double(-2*sum(scd_model_likelihood_rician(data,modelfun(x), opt.sigma_noise))), double(opt.st(~fixedparam)), [], [], [],[],double(opt.lb(~fixedparam)),double(opt.ub(~fixedparam)),[],optimoptions('fmincon','MaxIter',20,'display','off','DiffMinChange',0.03));
    opt.st(~fixedparam)=xopt; xopt = opt.st;
    
    %% OUTPUTS
    data_model=CHARMEDGPD(xopt,Prot,opt);
    if opt.fitT2
        xopt(9)=xopt(9)*opt.T2;
    end
    xopt(end+1) = residue;
    opt.xnames{end+1}='residue';
    
    xopt=xopt(~cellfun(@isempty,opt.xnames));
    opt.xnames = opt.xnames(~cellfun(@isempty,opt.xnames));
    for ff=1:length(opt.xnames)
        cell2struct(mat2cell(xopt(:)),opt.xnames,1);
    end
end

function x0 = addfixparameters(x0,x,fixedparam)
x0(~fixedparam)=x;

function data_model=CHARMEDGPD(x,Prot,opt)
% S0
if opt.fitT2
    S0 = x(8)*abs(opt.S0); T2 = x(9)*abs(opt.T2);
    S0 = S0*exp(-Prot(:,7)./T2);
else
    S0 = opt.S0;
end
% CHARMED
data_model = S0.*scd_model_CHARMED(x,opt);

if opt.plotfit && randn>1
    figure(3), scd_display_fits(opt.data,data_model,Prot); drawnow
end