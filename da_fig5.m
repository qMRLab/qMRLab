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
B1 = 1;

TR_range = 5000;

B1_double = zeros(length(TR_range), length(B1));


for ii=1:length(TR_range)
    alpha = deg2rad(nom_first_ang);
    T1 = 900;
    T2 = 9000;
    TE = 20;
    TR = TR_range(ii);
    crushFlag = 1;
    partialDephasingFlag = 0;
    partialDephasing = 0.3;
    df = 0;
    inc = 0;
    Nex = 1;

    for jj=1:length(B1)
        [sig1, ~] = da_blochsim(alpha, B1(jj), T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc, 'double');
        [sig2, ~] = da_blochsim(2*alpha, B1(jj), T1, T2, TE, TR, crushFlag, partialDephasingFlag, partialDephasing, df, Nex, inc, 'double');
        B1_double(ii,jj) = (acos(abs(sig2)./(8*abs(sig1))))^(1/3)./deg2rad(nom_first_ang);
    end

end

%save("da_fig5.mat", "nom_first_ang", "B1", "TR_range", "B1_hard", "B1_ideal")
