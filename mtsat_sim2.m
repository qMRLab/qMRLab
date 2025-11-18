
Model = qmt_spgr; 
Model.Prot.MTdata.Mat = [350, 2000];
Model.Prot.TimingTable.Mat(5) = 0.025 ;
Model.Prot.TimingTable.Mat(4) = Model.Prot.TimingTable.Mat(5) - 0.015 ;
Model.options.Readpulsealpha = 5;

x = struct;
x.F = 0.15;
x.kr = 32.67;
x.R1f = 1.25;
x.R1r = 1;
x.T2f = 0.038;
x.T2r = 1.14e-05;

Opt.SNR = 1000;
Opt.Method = 'Bloch sim';
Opt.ResetMz = false;

[FitResult, Smodel, Mz0] = Model.Sim_Single_Voxel_Curve(x,Opt);

MTon = Smodel;


%% PDw

PDw_Model = vfa_t1; 

params.EXC_FA = 6;
params.T1 = 900; % ms
params.TR = 28; % ms
    
PDw_anal = vfa_t1.analytical_solution(params);

%% T1w

T1w_Model = vfa_t1; 

paramsT1w.EXC_FA = 20;
paramsT1w.T1 = 900; % ms
paramsT1w.TR = 18; % ms
    
T1w_anal = vfa_t1.analytical_solution(paramsT1w);

%%
%
MTon2 = MTon*PDw_anal;

%%
%
MTR = (PDw_anal - MTon2)/PDw_anal
