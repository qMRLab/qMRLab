%% Load protocol

fname = 'configs/mtr-protocols.json'; 
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = jsondecode(str);

protocol = val.brown2013.philips;

fa = protocol.fa
tr = protocol.tr/1000
te = protocol.te/1000
offset = protocol.offset
mt_shape = protocol.mt_shape
mt_duration = protocol.mt_duration/1000
mt_angle = protocol.mt_angle

Model = qmt_spgr;
Model.Prot.MTdata.Mat = [mt_angle, offset];
Model.Prot.TimingTable.Mat(5) = tr ;
Model.Prot.TimingTable.Mat(1) = mt_duration;
Model.Prot.TimingTable.Mat(4) = Model.Prot.TimingTable.Mat(5) - (Model.Prot.TimingTable.Mat(1) + Model.Prot.TimingTable.Mat(2) + Model.Prot.TimingTable.Mat(3)) ;
Model.options.Readpulsealpha = fa;
Model.options.MT_Pulse_Shape = mt_shape

%% Load tissues

fname = 'configs/tissues.json'; 
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = jsondecode(str);

params = val.sled2001.late_wm_lesion;

x = struct;
x.F = params.F.mean;
x.kr = params.kf.mean / x.F;
x.R1f = params.R1f.mean;
x.R1r = 1;
x.T2f = params.T2f.mean/1000;
x.T2r = params.T2r.mean/(10^6);

Opt.SNR = 1000;
Opt.Method = 'Bloch sim';
Opt.ResetMz = false;

[FitResult, Smodel, Mz0] = Model.Sim_Single_Voxel_Curve(x,Opt);

MTR=1-Smodel