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
% [Msig1,MLong1]=da_blochsim(alpha, B1, T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc, 'hard')
% 
% 
% alpha2 = deg2rad(120);
% 
% [Msig2,MLong2]=da_blochsim(alpha2, B1, T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc, 'hard')
% 

%%

close all
clear all
clc

nom_first_ang = 60;
B1 = linspace(0.7, 1.3, 61);

TR_range = [linspace(10,100,10), linspace(200,1000,9), linspace(2000,10000,9)];

B1_hard = zeros(length(TR_range), length(B1));
B1_ideal = zeros(length(TR_range), length(B1));
B1_composite = zeros(length(TR_range), length(B1));


for ii=1:length(TR_range)
    alpha = deg2rad(nom_first_ang);
    T1 = 900;
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
        [sig1, ~] = da_blochsim(alpha, B1(jj), T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc, 'hard');
        [sig2, ~] = da_blochsim(2*alpha, B1(jj), T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc, 'hard');
        B1_hard(ii,jj) = acosd(abs(sig2)./(2*abs(sig1)))./nom_first_ang;

        [sig1, ~] = da_blochsim(alpha, B1(jj), T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc, 'ideal');
        [sig2, ~] = da_blochsim(2*alpha, B1(jj), T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc, 'ideal');
        B1_ideal(ii,jj) = acosd(abs(sig2)./(2*abs(sig1)))./nom_first_ang;        
        
        [sig1, ~] = da_blochsim(alpha, B1(jj), T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc, 'composite');
        [sig2, ~] = da_blochsim(2*alpha, B1(jj), T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc, 'composite');
        B1_composite(ii,jj) = acosd(abs(sig2)./(2*abs(sig1)))./nom_first_ang;  
    end

end

save("da_fig3.mat", "nom_first_ang", "B1", "TR_range", "B1_hard", "B1_ideal", "B1_composite")
