function M = SIRFSE_sim(Sim, Prot, wait)
%SIRFSE_sim Simulate magnetization after full sequence for all Ti and return Mzf

Param = Sim.Param;
if ~isfield(Param,'M0r'), Param.M0r = Param.F*Param.M0f; end
n  = length(Prot.ti);
M  = zeros(n,1);
ti = Prot.ti;
td = Prot.td;
h  = [];
Trf = Prot.InvPulse.Trf;
PulseShape = Prot.InvPulse.shape;
InvPulse = GetPulse(180,0,Trf,PulseShape);

% Create waitbar
if (~exist('wait','var') || isempty(wait))
    switch Sim.Opt.method
        case 'FastSim';  wait = 0;
        case 'FullSim';  wait = 1;
    end
end

if (wait)
    h = waitbar(0,'','Name','Simulating data','CreateCancelBtn',...
        'if ~strcmp(get(gcbf,''Name''),''canceling...''), setappdata(gcbf,''canceling'',1); set(gcbf,''Name'',''canceling...''); else delete(gcbf); end');
    setappdata(h,'canceling',0)
    setappdata(0,'Cancel',0);
end

% Loop over all Ti
for kk = [1:n]
    M0 = [0 0 Param.M0f Param.M0r];
    
        switch Sim.Opt.method
            case 'FastSim'
                M0 = [0 0 0 0]';  % Assume zero mag after FSE sequence           
            case 'FullSim'
                M0 = FSE_seq(Param,Prot,M0)'; % Compute after FSE sequence
        end
                
                % Recovery after acquisition
%                 [~, M_temp] = ode45(@(t,M) Bloch(t,M,Param), [0 td(kk)], M0);
%                 M0 = M_temp(end,:);
                M0 = BlochSol(td(kk),M0,Param); 
                
                % Inversion pulse
                [~, M_temp] = ode45(@(t,M) Bloch(t,M,Param,InvPulse), [0 Trf], M0);
                M0 = M_temp(end,:)';
                
                % Inversion Recovery
%                 [~, M_temp] = ode45(@(t,M) Bloch(t,M,Param), [0 ti(kk)], M0);
%                 M0 = M_temp(end,:);
                M0 = BlochSol(ti(kk),M0,Param); 
                
                % Mzf at acquisition time
%                  M(kk) = abs(M0(end, 3));
                 M(kk) = abs(M0(3));
        
    % Allows user to cancel
    if (wait)
        if getappdata(h,'canceling');
            setappdata(0,'Cancel',1);
            break;
        end
        % Update waitbar
        waitbar(kk/n,h, sprintf('Data Point %d / %d', kk,n));
    end  
    
end

% Delete the waitbar
delete(h)

end

