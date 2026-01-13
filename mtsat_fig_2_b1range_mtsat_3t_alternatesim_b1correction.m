% NOTE TO SELF: Possibilty of simulation validation of MTsat through the
% bloch simulator (i.e. know the true MTsat that happened during the
% simulation, prior to fitting)
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

%% B1 range

B1_true = 1
B1_min = B1_true*0.7
B1_max = B1_true*1.3

B1_range = linspace(B1_min, B1_max, 21)


%%

MTsats = zeros(1,length(B1_range))
MTRs = zeros(1,length(B1_range))
T1s = zeros(1,length(B1_range))

for ii=1:length(B1_range)
    protocol = protocols.pdw
    
    fa = protocol.fa*B1_range(ii)
    tr = protocol.tr/1000
    te = protocol.te/1000
    offset = protocol.offset
    mt_shape = protocol.mtshape
    mt_duration = protocol.mtduration/1000
    mt_angle = protocol.mtangle*B1_range(ii)

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
    x.R1f = params.R1f.mean;
    x.R1r = 1;
    x.T2f = params.T2f.mean/1000;
    x.T2r = params.T2r.mean/(10^6);
    
    Opt.SNR = 1000;
    Opt.Method = 'Bloch sim';
    Opt.ResetMz = false;
    
    [FitResult, MT_norm, PDw] = Model.Sim_Single_Voxel_Curve(x,Opt);
    
   
    
    %% Get PDw/T1w ratio from analytical

     PDw_Model = vfa_t1; 

     params.EXC_FA = 6*B1_range(ii);
     params.T1 = 1/params.R1f.mean; % Could improve by caclulating T1meas from qMT values
     params.TR = 0.032; % ms

     PDw_anal = vfa_t1.analytical_solution(params);

     T1w_Model = vfa_t1; 

     paramsT1w.EXC_FA = 20*B1_range(ii);
     paramsT1w.T1 = 1/params.R1f.mean; % ms
     paramsT1w.TR = 0.018; % ms

     T1w_anal = vfa_t1.analytical_solution(paramsT1w);
    
     PDwT1w_ratio = PDw_anal/T1w_anal
    %%
    
    Model = mt_sat;
    FlipAngle = 6; % These are the nominal flip angles used for fitting, so not corrected in these sims
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
    data.T1w=PDw/PDwT1w_ratio;
    data.PDw=PDw;
    
    data.B1map=B1_range(ii)
    
    FitResults = FitData(data,Model,0);
    MTsats(1,ii) = FitResults.MTSAT
    MTRs(1,ii) = FitResults.MTR
    T1s(1,ii) = FitResults.T1

end

%%
close all

figure(1)
plot(squeeze(B1_range), squeeze(MTRs), 'LineWidth', 5)
legend('Location','northoutside')
structHandler.figure = figure(1);
structHandler.xlabel = xlabel('B1 (n.u.)');
structHandler.ylabel = ylabel('MTR');
structHandler.legend = legend('Karakuzu2022 (Siemens 1)');
figureProperties_plot(structHandler)

figure(2)
plot(squeeze(B1_range), squeeze(MTsats), 'LineWidth', 5)
legend('Location','northoutside')
structHandler.figure = figure(2);
structHandler.xlabel = xlabel('B1 (n.u.)');
structHandler.ylabel = ylabel('MTsat');
structHandler.legend = legend('Karakuzu2022  (Siemens 1)');
figureProperties_plot(structHandler)

figure(3)
plot(squeeze(B1_range), squeeze(T1s), 'LineWidth', 5)
legend('Location','northoutside')
structHandler.figure = figure(3);
structHandler.xlabel = xlabel('B1 (n.u.)');
structHandler.ylabel = ylabel('T1');
structHandler.legend = legend('Karakuzu2022  (Siemens 1)');
figureProperties_plot(structHandler)

save("fig2b_mtsat.mat", "B1_range", "MTRs", "MTsats", "T1s")