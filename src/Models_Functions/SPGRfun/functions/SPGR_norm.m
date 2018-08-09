function [Mz0, Mevol] = SPGR_norm(Sim, Prot)
%SPGR_norm Simulate Mz0, magnetization of free pool on steady-state,
%without MT pulse

Param   = Sim.Param;
Rpulse  = GetPulse(Prot.Alpha, 0, Prot.Tp, 'sinc');
Param.G = computeG(0, Param.T2r, Param.lineshape);

nP = Prot.Npulse;
Mevol = zeros(nP,1);
ww = 0;
M0r = Param.M0f*Param.F;
M0 = [0 0 Param.M0f M0r];
Mread = 0;
Mprev = 0;
SScount = 0;

% Repeat acquisition to achieve steady state
for ii = 1:nP
    % Free precession Ts + Tm
    [~, M_temp] = ode23(@(t,M) Bloch(t,M,Param), [0 Prot.Ts+Prot.Tm], M0);
    M0 = M_temp(end,:);
    
    % Readout
    Mread = abs(M0(3));
    
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
    [~, M_temp] = ode23(@(t,M) Bloch(t,M,Param,Rpulse), [0 Prot.Tp], M0);
    M0 = M_temp(end,:);
    
    % Free precession Tr
    [~, M_temp] = ode23(@(t,M) Bloch(t,M,Param), [0 Prot.Tr], M0);
    M0 = M_temp(end,:);     
end

Mz0 = Mread;

end

