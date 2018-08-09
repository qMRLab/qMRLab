function [Mxy, Mevol] = bSSFP_sim(Sim, Prot, wait)

%bSSFP_sim Simulation function of on-resonance bSSFP
%Output: Measured |M_xy|

Param = Sim.Param;
PulseShape = Prot.Pulse.shape;

alpha = Prot.alpha;
Trf = Prot.Trf;
M0r = Param.F.*Param.M0f;

if (Prot.FixTR)
    TR = Prot.TR * ones(length(alpha),1);
else
    TR = Prot.Td + Trf;
end

nA = length(alpha);
nP = Prot.Npulse;
Mxy = zeros(nA,1);
Mevol = zeros(nA,nP);
stop = 0;
ww = 0;

M0 = [0 0 Param.M0f M0r]';
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
    SScount = 0;
    TE = (TR(kk)-Trf(kk))/2;
    Pulse = GetPulse(alpha(kk),0,Trf(kk),PulseShape);
   
    % Reset M to equilibrium
    if (Sim.Opt.Reset)
        M0 = [0 0 Param.M0f M0r]';
    else
        M0(1:2) = 0;
    end
    
    % Pre-pulse alpha/2 - TR/2
    if (Prot.prepulse)
        PrePulse = GetPulse(alpha(kk)/2,0,Trf(kk),PulseShape);
        [~, M_temp] = ode23(@(t,M) Bloch(t,M,Param,PrePulse), [0 Trf(kk)], M0);
        M0 = M_temp(end,:)';
        M0 = BlochSol(TE,M0,Param); 
    end
    
    % Repeat acquisition to achieve steady state
    for ii = 1:nP
        
        % Phase cycling
        M0(1) = -M0(1);
        M0(2) = -M0(2);
        
        % RF pulse
        [~, M_temp] = ode23(@(t,M) Bloch(t,M,Param,Pulse), [0 Trf(kk)], M0);
        M0 = M_temp(end,:)';
        
        % Free precession TE
        M0 = BlochSol(TE,M0,Param);
        
        % Readout
        Mread = norm([M0(1) M0(2)]); % read |Mxy|
%         Mread = abs(M0(2)); % read |My|
        
        % If steady state achieved, go to next point
        if ( Sim.Opt.SScheck && abs(Mread - Mprev)/Mprev <= Sim.Opt.SStol )
            SScount = SScount + 1;
            if (SScount >= 5)
                ww = ww + nP-ii; break;
            end
        end
        Mprev = Mread;
        Mevol(kk,ii) = Mread;
        
        % Free precession TE
        M0 = BlochSol(TE,M0,Param);               
        
        if (wait)
            % Allows user to cancel
            if getappdata(h,'canceling')
                stop = 1;
                setappdata(0,'Cancel',1);
                break;
            end  
            % Update waitbar
            ww = ww+1;
            waitbar(ww/(nA*nP),h,sprintf('Data Point %d/%d; Pulse %d/%d', kk,nA,ii,nP));
        end
    end
    
    if (stop) break; end
    
    Mxy(kk) = Mread;
    
end

% Delete waitbar
delete(h);

end

