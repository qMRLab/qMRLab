
T1_true = 1



%% Get PDw/T1w ratio from analytical

PDw_Model = vfa_t1;

params.EXC_FA = 7;
params.T1 = T1_true; % Could improve by caclulating T1meas from qMT values
params.TR = 0.025; % ms

PDw_anal = vfa_t1.analytical_solution(params);

T1w_Model = vfa_t1;

paramsT1w.EXC_FA = 20;
paramsT1w.T1 = T1_true; % ms
paramsT1w.TR = 0.018; % ms

T1w_anal = vfa_t1.analytical_solution(paramsT1w);

PDwT1w_ratio = (PDw_anal/sind(params.EXC_FA))/(T1w_anal/sind(paramsT1w.EXC_FA))
%%

Model = mt_sat;
FlipAngle = 7;
TR  = 0.025;
Model.Prot.MTw.Mat = [ FlipAngle TR ];
FlipAngle = 20;
TR = 0.018;
Model.Prot.T1w.Mat = [ FlipAngle TR];
FlipAngle = 7;
TR = 0.025;
Model.Prot.PDw.Mat = [ FlipAngle TR];

data = struct();
%data.MTw=MT_norm*PDw;
data.MTw=MTw*cosd(params.EXC_FA)
data.T1w=PDw/PDwT1w_ratio*cosd(paramsT1w.EXC_FA);
data.PDw=PDw*cosd(params.EXC_FA);
FitResults = FitData(data,Model,0);
MTsats = FitResults.MTSAT
MTRs = FitResults.MTR
T1s = FitResults.T1

%%

%%


Model = mt_sat;
FlipAngle = 7;
TR  = 0.025;
Model.Prot.MTw.Mat = [ FlipAngle TR ];
FlipAngle = 20;
TR = 0.018;
Model.Prot.T1w.Mat = [ FlipAngle TR];
FlipAngle = 7;
TR = 0.025;
Model.Prot.PDw.Mat = [ FlipAngle TR];

data = struct();
data.MTw=MTw*cosd(params.EXC_FA);
data.T1w=T1w*cosd(paramsT1w.EXC_FA);
data.PDw=PDw*cosd(params.EXC_FA);
FitResults = FitData(data,Model,0);
MTsats = FitResults.MTSAT
MTRs = FitResults.MTR
T1s = FitResults.T1