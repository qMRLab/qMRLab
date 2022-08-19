
N=100;

Model = qmt_spgr; 
Model.Prot.MTdata.Mat = [350, 2000];
Model.Prot.TimingTable.Mat(5) = 0.025 ;
Model.Prot.TimingTable.Mat(4) = Model.Prot.TimingTable.Mat(5) - 0.015 ;
Model.options.Readpulsealpha = 5;

F = normrnd(0.152, 0.023, N);
kf = normrnd(4.6, 1.3, N);
R1f = 0.25 + (2-0.25)*rand(100);
T2f = normrnd(0.031, 0.005, N);
T2r = normrnd(1.18e-05, 0.13e-05, N);

T1w_anal = zeros(10);
PDw_anal = zeros(10);
MTon = zeros(10);
MTon2 = zeros(10);
MTR = zeros(10);

for ii = 1:N
    disp(ii)
    for jj = 1:N
        x = struct;
        x.F = F(ii,jj);
        x.kr = kf(ii,jj)/x.F;
        x.R1f = R1f(ii,jj);
        x.R1r = 1;
        x.T2f = T2f(ii,jj);
        x.T2r = T2r(ii,jj);

        Opt.SNR = 1000;
        Opt.Method = 'Analytical equation';
        Opt.ResetMz = false;

        [FitResult, Smodel, ~] = Model.Sim_Single_Voxel_Curve(x,Opt);

        MTon(ii,jj) = Smodel;


        %% PDw

        PDw_Model = vfa_t1; 

        params.EXC_FA = 6;
        params.T1 = 1/x.R1f*1000; % ms
        params.TR = 28; % ms

        PDw_anal(ii,jj) = vfa_t1.analytical_solution(params);

        %% T1w

        T1w_Model = vfa_t1; 

        paramsT1w.EXC_FA = 20;
        paramsT1w.T1 = 1/x.R1f*1000; % ms
        paramsT1w.TR = 18; % ms

        T1w_anal(ii,jj) = vfa_t1.analytical_solution(paramsT1w);

        %%
        %
        MTon2(ii,jj) = MTon(ii,jj)*PDw_anal(ii,jj);

        %%
        %
        MTR(ii,jj) = (PDw_anal(ii,jj) - MTon2(ii,jj))/PDw_anal(ii,jj);
        
    end
end



