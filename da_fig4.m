% clear all
% close all
% clc
% 
% alpha = deg2rad(60);
% B1 = 1;
% T1 = 1000;
% T2 = 30;
% TE = 20;
% TR = 10000;
% crushFlag = 1;
% partialDephasingFlag = 1;
% partialDephasing = 0.3;
% df = 0;
% inc = 0;
% Nex = 100;
% 
% 
% [Msig1,MLong1]=da_blochsim(alpha, B1, T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc)
% 
% 
% alpha2 = deg2rad(120);
% 
% [Msig2,MLong2]=da_blochsim(alpha2, B1, T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc)
% 

%%

close all
clear all
clc

nom_first_ang = 60;
B1 = linspace(0.7, 1.3, 61);

TR_range = [linspace(10,100,10), linspace(200,1000,9), linspace(2000,10000,9)];

for ii=1:length(TR_range)
    alpha = deg2rad(nom_first_ang);
    T1 = 1000;
    T2 = 30;
    TE = 20;
    TR = TR_range(ii);
    crushFlag = 0;
    partialDephasingFlag = 1;
    partialDephasing = 0.3;
    df = 0;
    inc = 0;
    Nex = 100;


    B1_shortTR = zeros(1,length(B1));
    for jj=1:length(B1)
        [sig1, ~] = da_blochsim_composite(alpha, B1(jj), T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc, 'composite');
        [sig2, ~] = da_blochsim_composite(2*alpha, B1(jj), T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc,'composite');
        B1_shortTR(jj) = acosd(abs(sig2)./(2*abs(sig1)))./nom_first_ang;
    end

    plot(B1, B1_shortTR)
    title('TR = ' + string(TR_range(ii)) + ' milliseconds', 'T1 = 1 second');
    
    P = polyfit(B1,B1_shortTR,1);
    yfit = polyval(P,B1);
    hold on;
    plot(B1,B1,'r-.');
    eqn = string(" Linear: y = " + P(1)) + "x + " + string(P(2));
    text(min(B1),max(B1_shortTR),eqn,"HorizontalAlignment","left","VerticalAlignment","top")
    disp(B1_shortTR)
    hold off
    pause(0.5)
end

