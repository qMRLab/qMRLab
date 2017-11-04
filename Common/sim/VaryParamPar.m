function Sens = VaryParamPar(Vary, Sim, Prot, FitOpt, SensOpt, Method)
%VARYPARAM Performs Sensitivity analysis by varying 'Vary' parameter
% from min to max by step

Param = Sim.Param;
AddNoise = Sim.Opt.AddNoise;
SNR    = Sim.Opt.SNR;
min    = SensOpt.min;
max    = SensOpt.max;
step   = SensOpt.step;
runs   = SensOpt.runs;

if (~AddNoise); runs = 1; end

x = min:step:max;
Sens.x = x;
Sens.step = step;

switch Method
    case 'SIRFSE'
        fields = {'F';'kf';'kr';'R1f';'R1r';'Sf';'Sr';'M0f';'M0r'};
        Sens.MTdata  = zeros(length(x),length(Prot.ti));
    case 'bSSFP'
        fields = {'F';'kf';'kr';'R1f';'R1r';'T2f';'M0f';'M0r'};
        Sens.MTdata  = zeros(length(x),length(Prot.alpha));       
    case 'SPGR'
        fields = {'F';'kf';'kr';'R1f';'R1r';'T2f';'T2r'};
        Sens.MTdata  = zeros(length(x),length(Prot.Angles));
end

for ii = 1:length(fields)
    Sens.(fields{ii}).fit = zeros(length(x),runs);
end

% Create waitbar
h = waitbar(0, sprintf('Data 0/%0.0f',length(x)), 'Name', sprintf('Simulating %s sensitivity data', Vary),...
            'CreateCancelBtn', 'if ~strcmp(get(gcbf,''Name''),''canceling...''), setappdata(gcbf,''canceling'',1); set(gcbf,''Name'',''canceling...''); else delete(gcbf); end');
setappdata(h,'canceling',0);
setappdata(0,'Cancel',0);

for i = 1:length(x)
    switch Vary
        case 'F'
        	Param.F   = x(i);
            Param.kf  = Param.F*Param.kr;
            Param.M0r = Param.F*Param.M0f;
        case 'kf'
            Param.kf = x(i);
            Param.kr = Param.kf/Param.F;
        case 'kr'
            Param.kr = x(i);
            Param.kf = Param.kr*Param.F;
        case 'R1f'
            Param.R1f = x(i);
            Param.T1f = 1/Param.R1f;
        case 'R1r'
            Param.R1r = x(i);
            Param.T1r = 1/Param.R1r;
        case 'T2f'
            Param.T2f = x(i);
            Param.R2f = 1/Param.T2f;
        case 'T2r'
            Param.T2r = x(i);
            Param.R2r = 1/Param.T2r;
            Param.G   = computeG(0, Param.T2r, Param.lineshape);
        case 'M0f'
            Param.M0f = x(i);
            Param.M0r = Param.F*Param.M0f;
        case 'SNR'
            SNR = x(i);
    end
        Sim.Param = Param;
        
    switch Method
        case 'SIRFSE'
            M = SIRFSE_sim(Sim, Prot);
        case 'bSSFP'
            M = bSSFP_sim(Sim, Prot, 1);
        case 'SPGR'
            M = SPGR_sim(Sim, Prot, 1);
    end  

    if (getappdata(0, 'Cancel'));  break;  end
       
    Sens.MTdata(i,:) = M;

    for k = 1:runs
        if (AddNoise)
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
            case 'SIRFSE'; Fit = SIRFSE_fit(MTdata, Prot, FitOpt);
            case 'bSSFP';  Fit = bSSFP_fit(MTdata, Prot, FitOpt);
            case 'SPGR';   Fit = SPGR_fit(MTdata, Prot, FitOpt );
        end
        
        for ii = 1:length(fields)
            Sens.(fields{ii}).fit(i,k) = Fit.(fields{ii});
        end
        
    end
    
    if getappdata(h,'canceling'); setappdata(0,'Cancel',1); break; end 
    waitbar(i/length(x),h,sprintf('Data %0.0f/%0.0f',i,length(x)));
end

delete(h)       % DELETE the waitbar; don't try to CLOSE it.

for ii = 1:length(fields)
    Sens.(fields{ii}).mean = mean(Sens.(fields{ii}).fit,2);	
    Sens.(fields{ii}).std   = std(Sens.(fields{ii}).fit,0,2);
end

end