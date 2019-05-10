function NewSensResults = VaryParamReFit(SensResults, FitOpt)

% -------------------------------------------------------------------------
% NewSensResults = VaryParamReFit(SensResults, FitOpt)
% Fit a previously performed sensitivity analysis data (SensResults)
% with different fit options, without having to re-simulate the data
% -------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% -------------------------------------------------------------------------

% Build MTdata
NewSensResults = SensResults;
Results = SensResults.SimVaryResults;
NewResults = Results;

Protocol = SensResults.Prot;
fields = fieldnames(Results);
runs = SensResults.SimVaryOpt.runs;
nF = length(fields);

MTdata = [];
MTnoise = [];
R1map = [];
R1mapNoise = [];

for ii = 1:length(fields)
    MTdata = [MTdata; Results.(fields{ii}).MTdata];
    MTnoise = [MTnoise; Results.(fields{ii}).MTnoise];
    R1map = [R1map; Results.(fields{ii}).R1map];
    R1mapNoise = [R1mapNoise; repmat(Results.(fields{ii}).R1map,1,runs)];
end

% ReFitData
data.MTdata = MTnoise;
data.R1map = R1mapNoise;
data.Mask = [];
data.B1map = [];
data.B0map = [];

Fit = FitData( data, Protocol, FitOpt, Protocol.Method, 0 );


% Reshape things
par = Fit.fields;
count = 1;
for ii = 1:length(fields)
    num = length(Results.(fields{ii}).x);
    for jj = 1:length(par)
        fit = Fit.(par{jj})(count:count+num-1,:);
        NewResults.(fields{ii}).(par{jj}).fit = fit;
        NewResults.(fields{ii}).(par{jj}).mean = mean(fit,2);
        NewResults.(fields{ii}).(par{jj}).std = std(fit,0,2);
    end
    count = count+num;
end

NewSensResults.SimVaryResults = NewResults;

