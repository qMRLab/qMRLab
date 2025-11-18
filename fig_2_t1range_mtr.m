clear all, close all, clc

%% Load protocol

fname = 'configs/mtr-protocols.json'; 
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = loadjson(str);

protocol = val.brown2013.philips

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

MTRs = zeros(1,length(T1_range))

for ii=1:length(T1_range)
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
    
    [FitResult, Smodel, Mz0] = Model.Sim_Single_Voxel_Curve(x,Opt);
    
    MTRs(1,ii)=1-Smodel
end

save("fig4.mat", "T1_range", "MTRs", "T1_true")

%%
close all

figure(1)
plot(squeeze(T1_range), squeeze(MTRs), 'LineWidth', 5)
ylabel('MTR')
legend('Location','northoutside')
structHandler.figure = figure(1);
structHandler.xlabel = xlabel('T1 (s)');
structHandler.ylabel = ylabel('MTR');
structHandler.legend = legend('Brown2013  (Philips)');
figureProperties_plot(structHandler)
