function [mz]= MTsat_B1corr_factor_map(B1_map, Raobs, B1_ref,fitValues)
% Generate a multiplicative factor to correct MTsat maps
% B1_map is a relative B1 map, centered around 1
% R1 map is 1/T1 of the water pool in 1/ms
% B1 ref is the reference value == B1rms applied for the MT pulses
% fitValues comes from simulation from simWith_M0b_R1obs.m

%% Debug
% B1_map = b1_gauss;
% Raobs =  R1_s;
% B1_ref = b1_col_vals(1);
% fitValues = fitValues_dual;

%% Code
% Estimate the M0b from R1/Raobs generated from Brain_M0b_mapping_script.m
M0b = eval(fitValues.Est_M0b_from_R1);

% figure; imshow3Dfull(M0b, [0 0.2],jet)

% Calculate Relative Change caused by B1 to create multiplicative factor
b1 = B1_ref.*B1_map;
CF_act = eval(fitValues.fit_SS_eqn);

%nominal value
b1 = B1_ref;
CF_nom = eval(fitValues.fit_SS_eqn) ;

mz = (CF_nom-CF_act)./CF_act;


 