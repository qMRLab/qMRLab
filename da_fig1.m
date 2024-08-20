close all
clear all
clc

nom_first_ang = 60;
B1 = linspace(0.7, 1.3, 61);

true_FA = B1*nom_first_ang;
true_2FA = 2*B1*nom_first_ang;

TR_range = [linspace(10,100,10), linspace(200,1000,9), linspace(2000,10000,9)];

for ii=1:length(TR_range)
    params_FA.EXC_FA = true_FA;
    params_FA.T1 = 1000;
    params_FA.TR = TR_range(ii);

    params_2FA.EXC_FA = true_2FA;
    params_2FA.T1 = 1000;
    params_2FA.TR = TR_range(ii);

    B1_shortTR = acosd(vfa_t1.analytical_solution(params_2FA)./(2.*vfa_t1.analytical_solution(params_FA)))./nom_first_ang;

    plot(B1, B1_shortTR)
    title('TR = ' + string(TR_range(ii)) + ' milliseconds', 'T1 = 1 second');
    
    P = polyfit(B1,B1_shortTR,1);
    yfit = polyval(P,B1);
    hold on;
    plot(B1,B1,'r-.');
    eqn = string(" Linear: y = " + P(1)) + "x + " + string(P(2));
    text(min(B1),max(B1_shortTR),eqn,"HorizontalAlignment","left","VerticalAlignment","top")
    hold off
    pause(2)
end

