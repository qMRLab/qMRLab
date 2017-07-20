function PlotFittedModel(protocol, MODELNAME, fittedpars, constants, h, style)
% Plots the normalized measurements predicted by the model with
% the fitted parameters against the absolute dot product of the
% gradient and fibre directions.
%
% PlotFittedModel(protocol, MODELNAME, fittedpars, h)
% adds the plot to figure handle h.
%
% protocol is the imaging protocol.
%
% MODELNAME is the name identifying the model.
%
% fittedpars and the model parameter values.
%
% constants is a structure containing fixed values required for the model.
%
% h is a figure handle to add the plot to.  If not specified, a new figure
% appears.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

if(nargin<5)
    h = figure;
end

% Get estimated fibre direction and b=0 signal.
fibredir = GetFibreOrientation(MODELNAME, fittedpars);
b0est = GetB0(MODELNAME, fittedpars);

if(nargin<6)
    style = '-';
end

linedef{1} = ['r', style];
linedef{2} = ['b', style];
linedef{3} = ['g', style];
linedef{4} = ['m', style];
linedef{5} = ['c', style];
linedef{6} = ['k', style];
linedef{7} = ['y', style];

hold on;

scale = GetScalingFactors(MODELNAME);
xsc = fittedpars(1:(length(scale)-1))./scale(1:(end-1));
S_Meas = SynthMeas(MODELNAME, xsc, protocol, fibredir, constants);
Snormdw = S_Meas./b0est;
for j=1:length(protocol.uG)
    inds = find(protocol.G == protocol.uG(j) & protocol.delta == protocol.udelta(j) & protocol.smalldel == protocol.usmalldel(j));
    dps = abs(protocol.grad_dirs(inds,:)*fibredir);
    [t tinds] = sort(dps);
    plot(dps(tinds), Snormdw(inds(tinds)), linedef{j}, 'LineWidth', 2);
end
xlabel('|n.G|/|G|_{max}');
ylabel('S/S_0');

