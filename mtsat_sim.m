
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

MTon = Smodel*Mz0
MToff = Mz0
MTR=(MToff-MTon)/MToff

%%

ModelT1 = qmt_spgr; 
ModelT1.Prot.MTdata.Mat = [350, 2000];
ModelT1.Prot.TimingTable.Mat(5) = 0.011 ;
ModelT1.Prot.TimingTable.Mat(1) = 0.0502;
ModelT1.Prot.TimingTable.Mat(2) = 0.003;
ModelT1.Prot.TimingTable.Mat(3) = 0.0018;
ModelT1.Prot.TimingTable.Mat(4) = ModelT1.Prot.TimingTable.Mat(5)-ModelT1.Prot.TimingTable.Mat(1)-ModelT1.Prot.TimingTable.Mat(2)-ModelT1.Prot.TimingTable.Mat(3);

ModelT1.options.Readpulsealpha = 15;

[FitResultT1, SmodelT1, Mz0T1] = ModelT1.Sim_Single_Voxel_Curve(x,Opt);

T1w = Mz0T1;

%%