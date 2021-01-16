function [Msig1,Msig2,MLong]=afi_blochsim(alpha, T1, T2, TE, TR1, TR2, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc)
%IR_BLOCHSIM Bloch simulations of the GRE-AFI pulse sequence.
% Simulates 100 spins params.Nex repetitions of the AFI pulse
% sequences.
%
% params: Struct with the following fields:
%   alpha: Excitation pulse flip angle in radians.
%   TR1: Repetition time 1 (ms).
%   TR2: Repetition time 2 (ms).
%   TE: Echo time (ms).
%   T1: Longitudinal relaxation time (ms).
%   T2: Transverse relaxation time (ms).
%   Nex: Number of excitations
%   df: Off-resonance frequency of spins relative to excitation pulse (in Hz)
%   crushFlag: Numeric flag for perfect spoiling (1) or partial spoiling (2).
%   partialDephasing: Partial dephasing fraction (between [0, 1]). 1 = no dephasing, 0 = complete dephasing (sele
%   inc: Phase spoiling increment in degrees.
%
% Outputs:
%   MLong: Longitudinal magnetization at time TI (prior to excitation pulse).
%   Msig: Complex signal produced by the transverse magnetization at time TE after excitation.
%

%% Set up spin properties
%

Nf = 100;

if partialDephasingFlag
    phi = ((1-Nf/2):Nf/2)/Nf*2*pi*partialDephasing; % Radian phase vector going from 2Pi/Nf to 2Pi in 2Pi/Nf increments.
end

%% Calculate free-precession matrices
%

%"A" is decay and phase gained due to off resonance, "B" is regrowth

% Magnetization decayed (A) and regrowth (B) between the alpha pulse and measurement.
[Ate,Bte] = free_precess(TE,T1,T2,df);

% Magnetization decayed (A) and regrowth (B) between the measurement and the next TR.
[Atr1,Btr1] = free_precess(TR1-TE,T1,T2,df);

% Magnetization decayed (A) and regrowth (B) between the measurement and the next TR.
[Atr2,Btr2] = free_precess(TR2-TE,T1,T2,df);

%% Bloch Simulation
%

M = [zeros(2,Nf);ones(1,Nf)]; % Sets initial magnetization for every spin [0;0;1]
on = ones(1,Nf); % Vector to ensure size of matrices in further calculations 
	
Rfph = 0;       % Rf phase
Rfinc = inc;    

for n=1:Nex

    %Signal 1
    MLong = mean(M(3,:)); % Longitudinal magnetization just before excitation pulse

	A = Ate * th_rot(alpha, Rfph);
	B = Bte;
    
	M = A*M+B*on; % M is rotated, then decayed for TE. Regrowth factor is added.

	Msig1 = sum( squeeze(M(1,:)+1i*M(2,:)) ) / Nf; % Complex signal 1 by adding up all the spins
    
	M=Atr1*M+Btr1*on; % Relaxation during rest of TR1 after TE

    if crushFlag
        % To make sure spoiling is ideal
        M(1:2, :) = 0; 
    elseif partialDephasing
        for k=1:Nf
            M(:,k) = z_rot(phi(k))*M(:,k);  % Dephase spins.
        end
    end
    
    Rfph = Rfph+Rfinc; % Calculate the next RF phase
    Rfinc = Rfinc+inc; % Calculate the next RF increment
    
%     Msig2 = Msig1;
    
    %Signal 2
    MLong = mean(M(3,:)); % Longitudinal magnetization after signal 1

	A = Ate * th_rot(alpha, Rfph);
	B = Bte;
    
	M = A*M+B*on; % M is rotated, then decayed for TE. Regrowth factor is added.

	Msig2 = sum( squeeze(M(1,:)+1i*M(2,:)) ) / Nf; % Complex signal by adding up all the spins
    
	M=Atr2*M+Btr2*on; % Relaxation during rest of TR1 after TE

    if crushFlag
        % To make sure spoiling is ideal
        M(1:2, :) = 0; 
    elseif partialDephasing
        for k=1:Nf
            M(:,k) = z_rot(phi(k))*M(:,k);  % Dephase spins.
        end
    end
    
    Rfph = Rfph+Rfinc; % Calculate the next RF phase
    Rfinc = Rfinc+inc; % Calculate the next RF increment

end