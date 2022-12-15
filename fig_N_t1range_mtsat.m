clear all, close all, clc

%% Load protocol

fname = 'configs/mtsat-protocols.json'; 
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = loadjson(str);

protocols = val.karakuzu2022.siemens1

%% Load tissues

fname = 'configs/tissues.json'; 
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = loadjson(str);

tissue = val.sled2001.healthywhitematter;

%% T1 range

T1_true = 1/tissue{1}.R1f.mean
T1_min = T1_true*0.7
T1_max = T1_true*1.3

T1_range = linspace(T1_min, T1_max, 21)


%%

MTsats = zeros(1,length(T1_range))
MTRs = zeros(1,length(T1_range))
T1s = zeros(1,length(T1_range))

for ii=1:length(T1_range)
    protocol = protocols.pdw
    
    fa = protocol.fa
    tr = protocol.tr/1000
    te = protocol.te/1000
    offset = protocol.offset
    mt_shape = protocol.mtshape
    mt_duration = protocol.mtduration/1000
    mt_angle = protocol.mtangle

    Model = qmt_spgr;
    Model.Prot.MTdata.Mat = [mt_angle, offset];
    Model.Prot.TimingTable.Mat(5) = tr ;
    Model.Prot.TimingTable.Mat(1) = mt_duration;
    Model.Prot.TimingTable.Mat(4) = Model.Prot.TimingTable.Mat(5) - (Model.Prot.TimingTable.Mat(1) + Model.Prot.TimingTable.Mat(2) + Model.Prot.TimingTable.Mat(3)) ;
    Model.options.Readpulsealpha = fa;
    Model.options.MT_Pulse_Shape = mt_shape
    
    params = tissue{1}
    x = struct;
    x.F = params.F.mean;
    x.kr = params.kf.mean / x.F;
    x.R1f = 1/T1_range(ii);
    x.R1r = 1;
    x.T2f = params.T2f.mean/1000;
    x.T2r = params.T2r.mean/(10^6);
    
    Opt.SNR = 1000;
    Opt.Method = 'Bloch sim';
    Opt.ResetMz = false;
    
    [FitResult, MT_norm, PDw] = Model.Sim_Single_Voxel_Curve(x,Opt);
    
    protocol = protocols.t1w
    
    fa = protocol.fa
    tr = protocol.tr/1000
    te = protocol.te/1000

    Model = qmt_spgr;
    Model.Prot.MTdata.Mat = [mt_angle, offset];
    Model.Prot.TimingTable.Mat(5) = tr ;
    Model.Prot.TimingTable.Mat(1) = mt_duration;
    Model.Prot.TimingTable.Mat(4) = Model.Prot.TimingTable.Mat(5) - (Model.Prot.TimingTable.Mat(1) + Model.Prot.TimingTable.Mat(2) + Model.Prot.TimingTable.Mat(3)) ;
    Model.options.Readpulsealpha = fa;
    Model.options.MT_Pulse_Shape = mt_shape
    
    Opt.SNR = 1000;
    Opt.Method = 'Bloch sim';
    Opt.ResetMz = false;
    
    [FitResult, ~, T1w] = Model.Sim_Single_Voxel_Curve(x,Opt);
    
    Model = mt_sat;
    FlipAngle = 6;
    TR  = 0.032;
    Model.Prot.MTw.Mat = [ FlipAngle TR ];
    FlipAngle = 20;
    TR = 0.018;
    Model.Prot.T1w.Mat = [ FlipAngle TR];
    FlipAngle = 6;
    TR = 0.032;
    Model.Prot.PDw.Mat = [ FlipAngle TR];

    data = struct();
    data.MTw=MT_norm*PDw;
    data.T1w=T1w;
    data.PDw=PDw;
    FitResults = FitData(data,Model,0);
    MTsats(1,ii) = FitResults.MTSAT
    MTRs(1,ii) = FitResults.MTR
    T1s(1,ii) = FitResults.T1

end

%%
figure()
plot(squeeze(T1_range), squeeze(MTRs))
ylabel('MTR')
legend('Location','northoutside')

figure()
plot(squeeze(T1_range), squeeze(MTsats))
ylabel('MTsats')
legend('Location','northoutside')

figure()
plot(squeeze(T1_range), squeeze(T1s))
ylabel('T1s')
legend('Location','northoutside')
