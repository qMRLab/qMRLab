%%
clear all
close all
clc

%% Load protocols

fname = 'configs/mtsat-protocols.json'; 
fid = fopen(fname); 
raw = fread(fid,inf); 
str = char(raw'); 
fclose(fid); 
val = loadjson(str);

protocols = [val.Helms2008.protocol val.Weiskopf2013.protocol val.Campbell2018.protocol val.karakuzu2022.siemens1 val.karakuzu2022.ge1 val.York2022.protocol]
protocol_names = ['Helms2008', 'Weiskopf2013', 'Campbell2018', 'Karakuzu2022 Siemens 1', 'Karakuzu2022 GE1', 'York2022']

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

MTRsats = zeros(length(protocols),length(tissues))

for ii=1:length(protocols)
    protocol = protocols(ii).pdw
        
    fa = protocol.fa
    tr = protocol.tr/1000
    te = protocol.te/1000
    offset = protocol.offset
    mt_shape = protocol.mtshape
    mt_duration = protocol.mtduration/1000
    mt_angle = protocol.mtangle

    Model_qmt = qmt_spgr;
    Model_qmt.Prot.MTdata.Mat = [mt_angle, offset];
    Model_qmt.Prot.TimingTable.Mat(5) = tr ;
    Model_qmt.Prot.TimingTable.Mat(1) = mt_duration;
    Model_qmt.Prot.TimingTable.Mat(4) = Model_qmt.Prot.TimingTable.Mat(5) - (Model_qmt.Prot.TimingTable.Mat(1) + Model_qmt.Prot.TimingTable.Mat(2) + Model_qmt.Prot.TimingTable.Mat(3)) ;
    Model_qmt.options.Readpulsealpha = fa;
    Model_qmt.options.MT_Pulse_Shape = mt_shape
    

    for jj = 1:length(tissues)
        % Get MTnorm
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

        [FitResult, MT_norm, PDw] = Model_qmt.Sim_Single_Voxel_Curve(x,Opt);
        
        % Get PDw/T1w ratio from analytical
        
        pdw_protocol = protocol
        PDw_Model = vfa_t1;
        
        params.EXC_FA = pdw_protocol.fa;
        params.T1 = 1/params.R1f.mean; % Could improve by caclulating T1meas from qMT values
        params.TR = pdw_protocol.tr/1000; % ms
        
        PDw_anal = vfa_t1.analytical_solution(params);
        
        T1w_Model = vfa_t1;
        
        t1w_protocol = protocols(ii).t1w
        
        paramsT1w.EXC_FA = t1w_protocol.fa;
        paramsT1w.T1 = 1/params.R1f.mean; % ms
        paramsT1w.TR = t1w_protocol.tr/1000; % ms
        
        T1w_anal = vfa_t1.analytical_solution(paramsT1w);
        
        PDwT1w_ratio = PDw_anal/T1w_anal
        
        % Calc MTsat
        MTsat_Model = mt_sat;
        FlipAngle = pdw_protocol.fa; % These are the nominal flip angles used for fitting, so not corrected in these sims
        TR  = pdw_protocol.tr/1000;
        MTsat_Model.Prot.MTw.Mat = [ FlipAngle TR ];
        FlipAngle = t1w_protocol.fa; % These are the nominal flip angles used for fitting, so not corrected in these sims
        TR  = t1w_protocol.tr/1000;
        MTsat_Model.Prot.T1w.Mat = [ FlipAngle TR];
        FlipAngle = pdw_protocol.fa; % These are the nominal flip angles used for fitting, so not corrected in these sims
        TR  = pdw_protocol.tr/1000;
        MTsat_Model.Prot.PDw.Mat = [ FlipAngle TR];

        data = struct();
        data.MTw=MT_norm*PDw;
        data.T1w=PDw/PDwT1w_ratio;
        data.PDw=PDw;

        FitResults = FitData(data,MTsat_Model,0);
        MTsats(ii,jj) = FitResults.MTSAT
        MTRs(ii,jj) = FitResults.MTR
        T1s(ii,jj) = FitResults.T1
    end
end

%%
close all
figure(1)
protocol_names = {'Helms2008', 'Weiskopf2013', 'Campbell2018', 'Karakuzu2022 Siemens 1', 'Karakuzu2022 GE1', 'York2022'}
tissue_names = {'Healthy Cortical GM', 'Healthy WM', 'NAWM', 'Early WM MS Lesion', 'Late WM MS Lesion'}
for ii=1:length(protocols)
    scatter([1:5], MTsats(ii,:), 100, 'filled')
    structHandler.legend = legend(protocol_names)
    hold on
end
set(gca,'xtick',[1:5],'xticklabel',tissue_names)
xtickangle(45)
xlim([0 6])
legend('Location','northoutside')

structHandler.figure = figure(1);
structHandler.xlabel = xlabel('Protocols');
structHandler.ylabel = ylabel('MTsat');
figureProperties_plot(structHandler)

%%

save("fig0.mat", "protocol_names", "tissue_names", "MTsats")

