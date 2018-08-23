%% Mock notebook for Inversion Recovery signal equation comparison
%

[filePath, folderName] = fileparts(pwd);
while ~strcmp(folderName, 'qMRLab')
    cd(filePath)
    [filePath, folderName] = fileparts(pwd);
    if isempty(folderName)
        error('Could not find qMRLab folder in parent directories.')
    end
end

startup

%%
%

close all

%% Setup parameters
% All times are in seconds
% All flip angles are in degrees

params.TR = 5.0;
params.TI = linspace(0.001, params.TR, 1000);
            
params.TE = 0.004;
params.T2 = 0.040;
            
params.FA = 90;

params.signalConstant = 1;

%% Calculate signals
%

% Eq. 1
params.T1 = 0.900;
signal_WM = ir_equations(params, 'GRE-IR', 4);

% Eq. 2
params.T1 = 1.500;
signal_GM = ir_equations(params, 'GRE-IR', 4);

% Eq. 3
params.T1 = 4.000;
signal_CSF = ir_equations(params, 'GRE-IR', 4);

%% Plot Magnitude comparison of Eqs 1, 2, 3
%

h1.figure = figure(1);

h1.plot{1} = plot(params.TI, abs(signal_WM)); hold on
h1.plot{2} = plot(params.TI, abs(signal_GM));
h1.plot{3} = plot(params.TI, abs(signal_CSF));

h1.legend = legend({'T1 = 900 ms', 'T1 = 1500 ms', 'T1 = 4000 ms'}, 'Location', 'best');
h1.xlabel = xlabel('TI (s)');
h1.ylabel = ylabel('Signal (real)');

plotFigureProperties(h1)

%% Plot comparison of Eqs 1, 2, 3
%

h2.figure = figure(2);

h2.plot{1} = plot(params.TI, signal_WM); hold on
h2.plot{2} = plot(params.TI, signal_GM);
h2.plot{3} = plot(params.TI, signal_CSF);
xL = get(gca, 'XLim');
plot(xL, [0 0], 'k-', 'LineWidth', 3)

h2.legend = legend({'T1 = 900 ms', 'T1 = 1500 ms', 'T1 = 4000 ms', 'X-axis'}, 'Location', 'best');
h2.xlabel = xlabel('TI (s)');
h2.ylabel = ylabel('Signal (magnitude)');

plotFigureProperties(h2)

%% Plot comparison of Eqs 1, 2, 3
%

h3.figure = figure(3);

ax = gca;
ax.ColorOrderIndex = 3;

hold on

h3.plot{1} = plot(params.TI, abs(signal_CSF)); hold on

params.T1 = 4.000;
signal_CSF_TR = ir_equations(params, 'GRE-IR', 3);

h3.plot{2} = plot(params.TI, abs(signal_CSF_TR));

h3.legend = legend({'Eq. 3', 'Eq. 2'}, 'Location', 'best');
h3.xlabel = xlabel('TI (s)');
h3.ylabel = ylabel('Signal (magnitude)');

plotFigureProperties(h3)