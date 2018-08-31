function [Msig,MLong]=ir_blochsim(alpha, beta, TI, T1, T2, TE, TR, crushFlag, partialDephasing, df, Nex, inc)
%IR_BLOCHSIM Bloch simulations of the GRE-IR pulse sequence.
% Simulates 100 spins params.Nex repetitions of the IR pulse
% sequences.
%
% params: Struct with the following fields:
%   alpha: Inversion pulse flip angle in radians.
%   beta: Excitation pulse flip angle in degrees.
%   TI: Inversion time (ms).
%   TR: Repetition time (ms).
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

Nf = 100;	% Simulate 100 different gradient-spoiled spins.

%% Calculate free-precession matrices
%

%"A" is decay and phase gained due to off resonance, "B" is regrowth

% Magnetization decayed (A) and regrowth (B) between the beta pulse and measurement.
[Ate,Bte] = free_precess(TE,T1,T2,df);

% Magnetization decayed (A) and regrowth (B) between the alpha pulse and beta pulse.
[Ati,Bti] = free_precess(TI,T1,T2,df);

% Magnetization decayed (A) and regrowth (B) between the LAST measurement and the next TR.
[Atr,Btr] = free_precess(TR-TI-TE,T1,T2,df);

%%
%
M = [zeros(2,Nf);ones(1,Nf)]; % Sets initial magnetization for every spin [0;0;1]
on = ones(1,Nf); % Vector to ensure size of matrices in further calculations 
	
Rfph = 0;       % Rf phase
Rfinc = inc;    

for n=1:Nex %nth TR
    
    A1 = Ati * th_rot(alpha, Rfph);
    B1 = Bti;
    
    % Apply alpha pulse, then decay/regrow until beta pulse
    M = A1*M+B1*on;
    
    MLong = mean(M(3,:)); % Longitudinal magnetization just before excitation pulse
    
    % Crush signal at the end of TI1, but not during the TI2 
    if crushFlag == 1   % Complete spoiling
       M(1:2,:) = 0; 
    elseif crushFlag == 2 % Partial spoiling
       phi2 = ((1-Nf/2):Nf/2)/Nf*2*pi*partialDephasing;
       for k=1:Nf
       	   M(:,k) = z_rot(phi2(k))*M(:,k); % Dephase spins.
       end
    end

    A2 = Ate * th_rot(beta, Rfph);
    B2 = Bte;

    % Apply beta pulse, then decay/regrow until measurement time.
    M=A2*M+B2*on; 

    Msig = mean( squeeze(M(1,:)+1i*M(2,:)) ) * exp(-1i*Rfph); % Complexe transverse magnetization.

    A3 = Atr;
    B3 = Btr;

    % Decay/regrow  from the last measurement until the start of the next TR.
    M=A3*M+B3*on;

    M(1:2,:) = 0;   
    Rfph = Rfph+Rfinc; % Calculate the next RF phase
    Rfinc = Rfinc+inc; % Calculate the next RF increment

end
