function SimRndResults = VaryRndParam(Sim, Prot, FitOpt, SimRndOpt, RndParam, Method)
%VaryRndParam Multi Voxel simulation of normally distributed parameters

Param = Sim.Param;
n = SimRndOpt.NumVoxels;

switch Method
    case 'SIRFSE'
        fields = {'F';'kf';'kr';'R1f';'R1r';'Sf';'Sr';'M0f';'M0r'};
        SimRndResults.MTdata  = zeros(n,length(Prot.ti));     
    case 'bSSFP'
        fields = {'F';'kf';'kr';'R1f';'R1r';'T2f';'M0f';'M0r'};
        SimRndResults.MTdata  = zeros(n,length(Prot.alpha));     
    case 'SPGR'
        fields = {'F';'kf';'kr';'R1f';'R1r';'T2f';'T2r'};
        SimRndResults.MTdata  = zeros(n,length(Prot.FAmt));
end

for ii = 1:length(fields)
    SimRndResults.(fields{ii}) = zeros(n,1);
end

% Create waitbar
h = waitbar(0, sprintf('Data 0/%0.0f',n), 'Name', 'Simulating data',...
    'CreateCancelBtn', 'if ~strcmp(get(gcbf,''Name''),''canceling...''), setappdata(gcbf,''canceling'',1); set(gcbf,''Name'',''canceling...''); else delete(gcbf); end');
setappdata(h,'canceling',0)
setappdata(0,'Cancel',0);

tic;
for ii = 1:n
    Param.F   =  RndParam.F(ii);        Param.kr  =  RndParam.kr(ii);
    Param.kf  =  Param.kr.*Param.F;     Param.R1f =  RndParam.R1f(ii);
    Param.R1r =  RndParam.R1r(ii);      Param.T1f =  1/Param.R1f;
    Param.T1r =  1/Param.R1r;           Param.T2f =  RndParam.T2f(ii);
    Param.T2r =  RndParam.T2r(ii);      Param.R2f =  1/Param.T2f;
    Param.R2r =  1/Param.T2r;           Param.M0f =  RndParam.M0f(ii);
    Param.M0r =  Param.M0f * Param.F;   Param.G   =  computeG(0,Param.T2r, Param.lineshape);
    Sim.Param = Param;
    
    switch Method
        case 'SIRFSE';  M = SIRFSE_sim(Sim, Prot);
        case 'bSSFP';   M = bSSFP_sim(Sim, Prot, 1);
        case 'SPGR';    M = SPGR_sim(Sim, Prot, 1);
    end  
    
    if (getappdata(0, 'Cancel'));  break;   end
    
    SimRndResults.MTdata(ii,:) = M;
    
    if (Sim.Opt.AddNoise)
    	switch Method
			case {'SIRFSE', 'SPGR'}
            	MTdata = addNoise(M, SNR, 'mt');
        	case 'bSSFP'
            	MTdata = addNoise(M, SNR, 'magnitude');
        end
    else
        MTdata = M;
    end
    
    if (FitOpt.R1map)
        FitOpt.R1 = computeR1obs(Param);
    end
    
    switch Method
        case 'SIRFSE';  Fit = SIRFSE_fit(MTdata, Prot, FitOpt);
        case 'bSSFP';   Fit = bSSFP_fit(MTdata, Prot, FitOpt);
        case 'SPGR';    Fit = SPGR_fit(MTdata, Prot, FitOpt );
    end
    
    for jj = 1:length(fields)
        SimRndResults.(fields{jj})(ii) = Fit.(fields{jj});
    end
        
    % Update waitbar
    if getappdata(h,'canceling');  break;  end
    waitbar(ii/n,h,sprintf('Data %0.0f/%0.0f',ii,n));
end

delete(h);
SimRndResults.time = toc
SimRndResults.fields = fields;
end