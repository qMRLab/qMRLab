function [mz, Mevol] = SPGR_par(ParamVect, Protocol, SimOpt, wait)
% SPGR_sim Simulation function of off-resonance SPGR for given MT parameters and
% sequence of Delta and Alpha
% Output: normalized mz

Param.F = ParamVect(1);
Param.kr = ParamVect(2);
Param.kf = ParamVect(3);
Param.R1f = ParamVect(4);
Param.R1r = ParamVect(5);
Param.T1f = ParamVect(6);
Param.T1r = ParamVect(7);
Param.R2f = ParamVect(8);
Param.R2r = ParamVect(9);
Param.T2f = ParamVect(10);
Param.T2r = ParamVect(11);
Param.M0f = 1;
Param.M0r = Param.F;
Param.lineshape = SimOpt.lineshape;
Sim.Opt = SimOpt;
Sim.Param = Param;

Angles = Protocol.Angles;
Offsets = Protocol.Offsets;
nA = length(Angles);
nP = Protocol.Npulse;
Mz = zeros(nA,1);
Mevol = zeros(nA,nP);
stop = 0;
ww = 0;
Rpulse = GetPulse(Protocol.Alpha, 0, Protocol.Tp, 'sinc');
G0 = computeG(0, Param.T2r, SimOpt.lineshape);
M0 = [0 0 Param.M0f Param.M0r];
Mread = 0;
Mprev = 0;

h = [];
% Create waitbar
if (~exist('wait','var') || isempty(wait))
    wait = 1;   % waitbar is on by default
end

if (wait)
    h = waitbar(0,'','Name','Simulating data','CreateCancelBtn',...
        'if ~strcmp(get(gcbf,''Name''),''canceling...''), setappdata(gcbf,''canceling'',1); set(gcbf,''Name'',''canceling...''); else delete(gcbf); end');
    setappdata(h,'canceling',0)
    setappdata(0,'Cancel',0);
end

% Loop over all data points
for kk = 1:nA
    
    Pulse = GetPulse(Angles(kk), Offsets(kk), Protocol.Tm, Protocol.MTpulse.shape, Protocol.MTpulse.opt); 
    SScount = 0;
    G = computeG(Offsets(kk), Param.T2r, Param.lineshape);
    
    % Reset M to equilibrium
    if (Sim.Opt.Reset)
        M0 = [0 0 Param.M0f Param.M0r];
    else
        M0(1:2) = 0;
    end
    
    % Repeat acquisition to achieve steady state
    for ii = 1:nP
        
        % Spoiling
        M0(1:2) = 0;
        
        % MT RF pulse
        Param.G = G;
        [~, M_temp] = ode23(@(t,M) Bloch(t,M,Param,Pulse), [0 Protocol.Tm], M0);
        M0 = M_temp(end,:);
        
        % Free precession Ts
        [~, M_temp] = ode23(@(t,M) Bloch(t,M,Param), [0 Protocol.Ts], M0);
        M0 = M_temp(end,:);
%         M0 = BlochSol(Prot.Ts,M0',Param); 
        
        % Readout
        Mread = abs(M0(3));
        Mevol(kk,ii) = Mread;
        
        % If steady state achieved, go to next point
        if ( Sim.Opt.SScheck && abs(Mread - Mprev)/Mprev <= Sim.Opt.SStol )
            SScount = SScount + 1;
            if (SScount >= 5)
                ww = ww + nP-ii; break;
            end
        end
        Mprev = Mread;
        
        % Spoiling
        M0(1:2) = 0;
        
        % Read pulse
        Param.G = G0;
        [~, M_temp] = ode23(@(t,M) Bloch(t,M,Param,Rpulse), [0 Protocol.Tp], M0);
        M0 = M_temp(end,:);
        
        % Free precession Tr
        [~, M_temp] = ode23(@(t,M) Bloch(t,M,Param), [0 Protocol.Tr], M0);
        M0 = M_temp(end,:);     
              
        if (wait)
            % Allows user to cancel
            if getappdata(h,'canceling')
                stop = 1;
                setappdata(0,'Cancel',1);
                break;
            end
            % Update waitbar
            ww = ww+1;
            waitbar(ww/(nA*nP),h,sprintf('Data %d/%d; Pulse %d/%d', kk,nA,ii,nP));
        end
    end
    
    if (stop);  break;  end
    
    Mz(kk) = Mread;
    
end

% Delete waitbar
delete(h);

% Normalisation
Mz0 = SPGR_norm(Sim,Protocol);
mz = Mz / Mz0;

end

