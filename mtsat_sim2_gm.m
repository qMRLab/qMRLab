
Model = qmt_spgr; 
Model.Prot.MTdata.Mat = [350, 2000];
Model.Prot.TimingTable.Mat(5) = 0.025 ;
Model.Prot.TimingTable.Mat(4) = Model.Prot.TimingTable.Mat(5) - 0.015 ;
Model.options.Readpulsealpha = 5;

x = struct;
x.F = 0.068;
x.kr = 2.6/x.F;
x.R1f = 0.6;
x.R1r = 1;
x.T2f = 0.062;
x.T2r = 0.96e-05;

Opt.SNR = 1000;
Opt.Method = 'Bloch sim';
Opt.ResetMz = false;

[FitResult, Smodel, Mz0] = Model.Sim_Single_Voxel_Curve(x,Opt);

MTon = Smodel;


%% PDw

PDw_Model = vfa_t1; 

params.EXC_FA = 6;
params.T1 = 1/x.R1f*1000; % ms
params.TR = 28; % ms
    
PDw_anal = vfa_t1.analytical_solution(params);

%% T1w

T1w_Model = vfa_t1; 

paramsT1w.EXC_FA = 20;
paramsT1w.T1 = 1/x.R1f*1000; % ms
paramsT1w.TR = 18; % ms
    
T1w_anal = vfa_t1.analytical_solution(paramsT1w);

%%
%
MTon2 = MTon*PDw_anal;

%%
%
MTR = (PDw_anal - MTon2)/PDw_anal
