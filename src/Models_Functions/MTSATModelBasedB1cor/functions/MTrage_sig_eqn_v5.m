%% This code is meant to solve the signal equations presented in Deichmann et al., 2000 for optimizing an MP-RAGE sequence
% The goal of this project is a multi-segment gre readout for ihMT imaging.
function Sig= MTrage_sig_eqn_v5(echospacing, flip, T1, TD, numExcitation, M0, MT_drop, B1field,MT_b1_corr)

%% Test parameters
% echospacing= Params.echospacing; % The echo spacing of the GRE readout
% numExcitation = Params.numExcitation; % in my implementation, only odd numbers work. 
% TD = Params.TD; % dead time in sequence, for SAR 
% flip = Params.flipAngle; % flip angle
% MT_drop = 0; % At steady state, how much does the signal drop? 
% B1field = 1;
% MT_b1_corr = 1;
% T1 = 1;
% M0 = 1;

%% Equations
flip_a = (flip*B1field) * pi / 180; % correct for B1 and convert to radians

%% Following readout you magnetization (M2) = A1 + M1 * B , derivation at the bottom of function. 

x = cos(flip_a) ;
y = exp(-echospacing/T1);

B1 = (x*y)^numExcitation;
% A1 = 0;
% for i = 1:numExcitation
%    A1 = A1 + M0*(x*y)^(i-1);
%    A1 = A1 - M0*(x*y)^(i)/x ;
% end

%% redo based on result from Munsch et al 2021 ihMT paper:
A1 = M0*(1-y)* ( (1- cos(flip_a)^numExcitation * exp(-numExcitation*echospacing/T1)) / (1- x*y) );

%% You then have some time TD for T1 relaxation, M3 = A2 + B2*M2
A2 = M0 * (1 - exp(-TD / T1));
B2 =  exp( -TD  / T1    );

%% Following TD, your MTsat pulses knock down your longitudinal relaxation by factor MTdrop M4 = A3 + M3 * B3

B3 = (1-(MT_drop*MT_b1_corr));


%% Since M4 = M1 and we want to solve for M1
% M4 = (A2 + B2* (A1 + M1 * B1)) * B3
% M4 = A2*B3 +B2*A1 + B1*B2*B3 *M4
M = (A2*B3 + A1*B2*B3) / (1-B1*B2*B3); % + A1*B2*B3

% With central encoding we readout M with sin(flip)
Sig = sin(flip_a) * M;






% 
% DERIVE M1 = A/(1-B) 
% M4 = A3 + B3 * M3
% M4 = A3 + B3 * (A2 + B2 * (A1 + B1 * M1))
% M4 = A3 + B3 *(A2 + B2*A1 + B2*B1*M1)
% M4 = A3 + B3*A2 +B3*B2*A1 + B3*B2*B1*M1
% 1 = (A3 + B3*A2 +B3*B2*A1 + B3*B2*B1*M1)/M1
% M1 - B3*B2*B1*M1 = A3 + B3*A2 +B3*B2*A1
% M1( 1-B) = A
% M1 = A/(1-B)













