close all
clear all
clc

nom_first_ang = 60;
B1 = linspace(0.7, 1.3, 61);

true_FA = B1*nom_first_ang;
true_2FA = 2*B1*nom_first_ang;

TR_range = [linspace(10,100,10), linspace(200,1000,9), linspace(2000,10000,9)];

B1_varTR = zeros(length(TR_range), length(B1), 3);

linfit = zeros(length(TR_range),2,3);

for ii=1:length(TR_range)
    params_FA.EXC_FA = true_FA;
    params_FA.T1 = 900;
    params_FA.TR = TR_range(ii);

    params_2FA.EXC_FA = true_2FA;
    params_2FA.T1 = 900;
    params_2FA.TR = TR_range(ii);

    B1_varTR(ii,:,1) = acosd(vfa_t1.analytical_solution(params_2FA)./(2.*vfa_t1.analytical_solution(params_FA)))./nom_first_ang;    
    linfit(ii,:,1) = polyfit(B1,B1_varTR(ii,:,1),1);
    
    params_FA.T1 = 1500;
    params_2FA.T1 = 1500;

    B1_varTR(ii,:,2) = acosd(vfa_t1.analytical_solution(params_2FA)./(2.*vfa_t1.analytical_solution(params_FA)))./nom_first_ang;    
    linfit(ii,:,2) = polyfit(B1,B1_varTR(ii,:,2),1);

    params_FA.T1 = 4000;
    params_2FA.T1 = 4000;

    B1_varTR(ii,:,3) = acosd(vfa_t1.analytical_solution(params_2FA)./(2.*vfa_t1.analytical_solution(params_FA)))./nom_first_ang;    
    linfit(ii,:,3) = polyfit(B1,B1_varTR(ii,:,3),1);    
    
end

save("da_fig1.mat", "nom_first_ang", "B1", "TR_range", "B1_varTR", "linfit")
