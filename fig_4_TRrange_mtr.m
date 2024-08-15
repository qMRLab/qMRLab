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

%% TR range

TR_min = 21
TR_max = 91

TR_range = linspace(TR_min, TR_max, 21)


%%


MTRs = zeros(1,length(TR_range))

for ii=1:length(TR_range)
    fa = protocol.fa
    tr = TR_range(ii)/1000
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
    x.R1f = tissue{1}.R1f.mean;
    x.R1r = 1;
    x.T2f = params.T2f.mean/1000;
    x.T2r = params.T2r.mean/(10^6);
    
    Opt.SNR = 1000;
    Opt.Method = 'Bloch sim';
    Opt.ResetMz = false;
    
    [FitResult, Smodel, Mz0] = Model.Sim_Single_Voxel_Curve(x,Opt);
    
    MTRs(1,ii)=1-Smodel

end

trueTR = protocol.tr

save("fig6.mat", "TR_range", "MTRs", "trueTR")

%%
close all

figure(1)
plot(squeeze(TR_range), squeeze(MTRs), 'LineWidth', 5)
ylabel('MTR')
legend('Location','northoutside')
structHandler.figure = figure(1);
structHandler.xlabel = xlabel('TR');
structHandler.ylabel = ylabel('MTR');
structHandler.legend = legend('Brown2013  (Philips)');
figureProperties_plot(structHandler)
