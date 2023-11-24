%%
clear all
close all
clc

%% Load protocols

fname = 'configs/mtr-protocols.json'; 
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = loadjson(str);

protocols = [val.brown2013.siemens val.brown2013.philips val.karakuzu2022.siemens1 val.karakuzu2022.ge1]
protocol_names = ['Brown2013 Siemens', 'Brown2013 Philips', 'Karakuzu2022 Siemens 1', 'Karakuzu2022 GE1']

%% Load tissues

fname = 'configs/tissues.json'; 
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = loadjson(str);

tissues = [val.sled2001.healthycorticalgreymatter val.sled2001.healthywhitematter val.sled2001.nawm val.sled2001.earlywmlesion val.sled2001.latewmlesion];
tissue_names = ['Healthy Cortical GM', 'Healthy WM', 'NAWM', 'Early WM MS Lesion', 'Late WM MS Lesion']

%%

MTRs = zeros(length(protocols),length(tissues))

for ii=1:length(protocols)
    protocol = protocols(ii)
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
    
    for jj = 1:length(tissues)
        params = tissues(jj)
        params = params {1}
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

        MTRs(ii,jj)=1-Smodel
    end
end

%%
close all
figure(1)
protocol_names = {'Brown2013 Siemens', 'Brown2013 Philips', 'Karakuzu2022 Siemens 1', 'Karakuzu2022 GE1'}
tissue_names = {'Healthy Cortical GM', 'Healthy WM', 'NAWM', 'Early WM MS Lesion', 'Late WM MS Lesion'}
for ii=1:length(protocols)
    scatter([1:5], MTRs(ii,:), 100, 'filled')
    structHandler.legend = legend(protocol_names)
    hold on
end
set(gca,'xtick',[1:5],'xticklabel',tissue_names)
xtickangle(45)
xlim([0 6])
legend('Location','northoutside')

structHandler.figure = figure(1);
structHandler.xlabel = xlabel('Protocols');
structHandler.ylabel = ylabel('MTR');
figureProperties_plot(structHandler)

