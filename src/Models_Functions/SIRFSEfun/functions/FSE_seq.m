function M0 = FSE_seq(Param, Prot ,M0)
%FSE_seq Simulate FSE  acquisition sequence and returns Mz at the end

Trf = Prot.FSE.Trf;
Tr  = Prot.FSE.Tr;
Pulse180 = GetPulse(180,0,Trf,'sinc');
Pulse90  = GetPulse(90,0,Trf,'sinc');

% 90 pulse
[~, M_temp] = ode45(@(t,M) Bloch(t,M,Param,Pulse90), [0 Trf], M0);
M0 = M_temp(end,:);

for i=1:Prot.FSE.Npulse-1
    % pulse 180
    [~, M_temp] = ode45(@(t,M) Bloch(t,M,Param,Pulse180), [0 Trf], M0);
    M0 = M_temp(end,:);
    
    % free
%     [~, M_temp] = ode45(@(t,M) Bloch(t,M,Param), [0 (Tr-Trf)], M0);
%     M0 = M_temp(end,:);
    M0 = BlochSol((Tr-Trf),M0',Param); 
    
end

% last pulse 180
[~, M_temp] = ode45(@(t,M) Bloch(t,M,Param,Pulse180), [0 Trf], M0);

% Simulate spoiling gradients by setting Mx, My = 0
M0 = [0 0 M_temp(end,3:4)]; 

end

