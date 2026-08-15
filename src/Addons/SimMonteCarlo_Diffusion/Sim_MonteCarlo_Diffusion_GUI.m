function varargout = Sim_MonteCarlo_Diffusion_GUI(Model)
%SIM_MONTECARLO_DIFFUSION_GUI  Pack axons, then diffuse particles through them.
%
%   Sim_MonteCarlo_Diffusion_GUI(Model)       open the window for a model
%   fig = Sim_MonteCarlo_Diffusion_GUI(Model) ...and return its figure handle
%
%   Left panel packs a set of axons (or loads a saved packing) and reports its
%   volume fractions; right panel sets the particle count, permeability and
%   diffusion coefficient; Update runs the Monte Carlo simulation.
%
%   Built in code -- no .fig, no gui_mainfcn. It stays a LEGACY figure: the
%   packing and simulation paths call axes(...) and plot into gca. See
%   docs/adr/0001-gui-migration.md, F2.
%
%   WHAT CHANGED IN THE REBUILD, AND WHAT DID NOT
%
%   Changed: every component here was positioned in CHARACTER units, which are a
%   font metric -- the same rectangle is a different size on every machine. They
%   are normalized now, computed from the rendered geometry
%   (Test/GUI/evidence/before_F2/MONTECARLO_MEASURED_GEOMETRY.txt).
%
%   Changed: the SimMCdiff axes. It sat at normalized y = -0.128, hanging ~60 px
%   below its panel, and nothing drew into it -- MonteCarloSim called
%   axes(handles.uipanel12), which CREATES A NEW AXES on every Update and stacks
%   them. It is inside its panel now and it is the one the simulation draws into.
%
%   NOT changed: the label boxes keep the sizes they had -- text_Naxons measures
%   131x12 px against 132x13 before -- and the `if ~ismac` FontSize 7 shrink is
%   untouched. Giving the labels room for their own text is a layout pass, scoped
%   separately from this conversion.
%
%   See also: Sim_MonteCarlo_Diffusion, axons_setup, process_packing
%
% ----------------------------------------------------------------------------------------------------
% Written by: Tanguy Duval, 2016. Rebuilt off GUIDE in Stage F2.
% ----------------------------------------------------------------------------------------------------

    NAME = 'SimMCdiff';

    if nargin < 1 || isempty(Model)
        Model = getappdata(0, 'Model');
    end
    if isempty(Model)
        error('qMRLab:Sim:NoModel', ...
            'No model to simulate. Pass one, or open qMRLab first.');
    end

    fig = findall(groot, 'Type', 'figure', 'Tag', 'Simu', 'Name', NAME);
    if isempty(fig)
        fig = buildWindow(NAME);
    else
        fig = fig(1);
        figure(fig);
    end

    showModel(fig, Model);

    if nargout, varargout{1} = fig; end
end

% ----------------------------------------------------------------------------
function fig = buildWindow(name)
    fig = figure( ...
        'Tag',              'Simu', ...
        'Name',             name, ...
        'Units',            'pixels', ...
        'Position',         [644 406 857 807], ...
        'Color',            qmrlabUIColor('viewerChrome'), ...
        'MenuBar',          'none', ...
        'ToolBar',          'figure', ...
        'NumberTitle',      'off', ...
        'IntegerHandle',    'off', ...
        'Resize',           'off', ...
        'HandleVisibility', 'callback', ...
        'Visible',          'off');
    movegui(fig, 'onscreen');

    handles        = struct();
    handles.Simu   = fig;
    handles.output = fig;

    % ------------------------------------------------------- simulation set-up
    handles.uipanel9 = uipanel( ...
        'Parent',     fig, ...
        'Tag',        'uipanel9', ...
        'Title',      'Simulation parameters', ...
        'Units',      'normalized', ...
        'Position',   [0.0151692 0.625774 0.976663 0.372986], ...
        'FontSize',   10, ...
        'BorderType', 'none');

    handles.OptionsPanel = uipanel( ...
        'Parent',     handles.uipanel9, ...
        'Tag',        'OptionsPanel', ...
        'Title',      'Axon Packing', ...
        'Units',      'normalized', ...
        'Position',   [0.00358423 0.0206186 0.746714 0.931271], ...
        'BorderType', 'etchedin');

    handles.axes_axonDist = axes('Parent', handles.OptionsPanel, ...
        'Tag', 'axes_axonDist', 'Units', 'normalized', ...
        'Position', [0.3157 0.5741 0.2529 0.2890]);
    handles.axes_axonPack = axes('Parent', handles.OptionsPanel, ...
        'Tag', 'axes_axonPack', 'Units', 'normalized', ...
        'Position', [0.6184 0.3004 0.3721 0.5589]);

    handles.text25 = label(handles.OptionsPanel, 'text25', ...
        'Use a preset packing:', [0.011282 0.81321 0.2484 0.068723]);
    handles.preset_packing = uicontrol('Parent', handles.OptionsPanel, ...
        'Style', 'popupmenu', 'Tag', 'preset_packing', 'String', {' '}, ...
        'Units', 'normalized', 'Position', [0.0086607 0.7036 0.26252 0.085904], ...
        'Callback', @(src, ~) preset_packing_Callback(src, [], guidata(src)));
    if ispc, set(handles.preset_packing, 'BackgroundColor', 'white'); end

    handles.text26 = label(handles.OptionsPanel, 'text26', ...
        'Or pack a new set:', [0.014508 0.63297 0.24356 0.049633]);

    handles.text_Naxons = label(handles.OptionsPanel, 'text_Naxons', ...
        '# axons: ', [0.0080558 0.55279 0.2113 0.049633]);
    handles.slider_Naxons = slider(handles.OptionsPanel, 'slider_Naxons', ...
        [0.23871 0.54134 0.024195 0.068723], 50, 400, 100, [0.14285714 1], ...
        @slider_Naxons_Callback);

    handles.text_dmean = label(handles.OptionsPanel, 'text_dmean', ...
        'mean diameter: ', [0.0080558 0.43825 0.21775 0.049633]);
    handles.slider_dmean = slider(handles.OptionsPanel, 'slider_dmean', ...
        [0.23871 0.41535 0.024195 0.076359], 0.1, 20, 3, [0.02631579 0.1], ...
        @slider_dmean_Callback);

    handles.text_dvar = label(handles.OptionsPanel, 'text_dvar', ...
        'Diameter variance: ', [0.0080558 0.31608 0.22582 0.049633]);
    handles.slider_dvar = slider(handles.OptionsPanel, 'slider_dvar', ...
        [0.23871 0.29699 0.024195 0.076359], 0, 10, 1, [0.05 0.1], ...
        @slider_dvar_Callback);

    handles.text_gap = label(handles.OptionsPanel, 'text_gap', ...
        'Gap between axons: ', [0.0080558 0.20154 0.23388 0.049633]);
    handles.slider_gap = slider(handles.OptionsPanel, 'slider_gap', ...
        [0.23871 0.17863 0.024195 0.076359], 0, 20, 0.5, [0.005 0.1], ...
        @slider_gap_Callback);

    handles.run_pack = uicontrol('Parent', handles.OptionsPanel, ...
        'Style', 'pushbutton', 'Tag', 'run_pack', 'String', 'Pack !', ...
        'Units', 'normalized', 'Position', [0.076407 0.081911 0.11291 0.079541], ...
        'BackgroundColor', qmrlabUIColor('accent'), ...
        'ForegroundColor', qmrlabUIColor('onTheAccent'), ...
        'Callback', @(src, ~) run_pack_Callback(src, [], guidata(src)));

    handles.tableVolumes = uitable('Parent', handles.OptionsPanel, ...
        'Tag', 'tableVolumes', 'Units', 'normalized', ...
        'Position', [0.34195 0.10404 0.1984 0.34362], ...
        'RowName', {'FVF'; 'FR'; 'MVF'; 'AVF'}, 'ColumnName', {}, ...
        'ColumnWidth', {'auto', 'auto'}, 'FontSize', 10);

    handles.save_pack = uicontrol('Parent', handles.OptionsPanel, ...
        'Style', 'pushbutton', 'Tag', 'save_pack', 'String', 'Save', ...
        'Units', 'normalized', 'Position', [0.77584 0.097182 0.059278 0.079541], ...
        'Callback', @(src, ~) save_pack_Callback(src, [], guidata(src)));

    % ------------------------------------------------------ Monte Carlo set-up
    handles.Panel = uipanel( ...
        'Parent',   handles.uipanel9, ...
        'Tag',      'Panel', ...
        'Title',    'Monte Carlo', ...
        'Units',    'normalized', ...
        'Position', [0.759804 0.014652 0.230392 0.934066]);

    handles.text_trans = label(handles.Panel, 'text_trans', ...
        'Permeability: ', [0.057476 0.8111 0.49141 0.049485]);
    handles.slider_trans = slider(handles.Panel, 'slider_trans', ...
        [0.86975 0.7889 0.077764 0.069786], 0, 1, 0, [0.1 0.1], ...
        @slider_trans_Callback);

    handles.text_numelparticle = label(handles.Panel, 'text_numelparticle', ...
        'Number of particles: ', [0.057476 0.60936 0.81554 0.053292]);
    handles.slider_numelparticle = slider(handles.Panel, 'slider_numelparticle', ...
        [0.86975 0.5935 0.077764 0.069786], 1, 3000, 100, [0.033344 0.1], ...
        @slider_numelparticle_Callback);

    handles.text_Dcoef = label(handles.Panel, 'text_Dcoef', ...
        'Diffusion coefficient: ', [0.057476 0.35432 0.84691 0.1142]);
    handles.slider_Dcoef = slider(handles.Panel, 'slider_Dcoef', ...
        [0.86975 0.40317 0.077764 0.069786], 0.1, 5, 1.5, [0.10204082 1], ...
        @slider_Dcoef_Callback);

    handles.text_Step = label(handles.Panel, 'text_Step', '', ...
        [0.15158 0.12846 0.79594 0.16495]);

    % ------------------------------------------------------------ plot results
    handles.uipanel12 = uipanel( ...
        'Parent',        fig, ...
        'Tag',           'uipanel12', ...
        'Title',         'Plot Results', ...
        'TitlePosition', 'lefttop', ...
        'Units',         'normalized', ...
        'Position',      [0.0151692 0.0173482 0.976663 0.576208], ...
        'FontSize',      10, ...
        'BorderType',    'none');

    % Was [0.25 -4.03333 101.125 28.3333] in CHARACTERS -- normalized y = -0.128,
    % i.e. its bottom 60 px, x tick labels included, below the panel.
    handles.SimMCdiff = axes('Parent', handles.uipanel12, ...
        'Tag', 'SimMCdiff', 'Units', 'normalized', ...
        'Position', [0.08 0.13 0.86 0.74]);

    handles.SimMCdiffUpdate = uicontrol('Parent', handles.uipanel12, ...
        'Style', 'pushbutton', 'Tag', 'SimMCdiffUpdate', 'String', 'Update', ...
        'Units', 'normalized', 'Position', [0.808219 0.93463 0.170254 0.0501509], ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', qmrlabUIColor('accent'), ...
        'ForegroundColor', qmrlabUIColor('onTheAccent'), ...
        'Callback', @(src, ~) SimMCdiffUpdate_Callback(src, [], guidata(src)));

    drawnow;   % the standard toolbar is not there to be found until the figure is
    bar = findall(fig, 'Type', 'uitoolbar');
    if isempty(bar); bar = uitoolbar(fig, 'Tag', 'uitoolbar1'); end
    handles.uitoolbar1 = bar(1);
    handles.helpbutton = uipushtool(handles.uitoolbar1, 'Tag', 'helpbutton', ...
        'Separator', 'on', 'TooltipString', 'Help', ...
        'ClickedCallback', @(~,~) doc('Sim_MonteCarlo_Diffusion_GUI'));
    try
        [cdata, map] = imread(fullfile(matlabroot, 'toolbox', 'matlab', 'icons', 'helpicon.gif'));
        handles.helpbutton.CData = ind2rgb(cdata, map);
    catch
    end

    guidata(fig, handles);
    fig.Visible = 'on';
end

function h = label(parent, tag, text, pos)
    h = uicontrol('Parent', parent, 'Style', 'text', 'Tag', tag, ...
                  'String', text, 'Units', 'normalized', 'Position', pos);
end

function h = slider(parent, tag, pos, lo, hi, value, step, callback)
    h = uicontrol('Parent', parent, 'Style', 'slider', 'Tag', tag, ...
                  'Units', 'normalized', 'Position', pos, ...
                  'Min', lo, 'Max', hi, 'Value', value, 'SliderStep', step, ...
                  'BackgroundColor', [.9 .9 .9], ...
                  'Callback', @(src, ~) callback(src, [], guidata(src)));
end

% ----------------------------------------------------------------------------
function showModel(fig, Model)
%SHOWMODEL  Point the window at a model. Runs on EVERY open.
    setappdata(0, 'Model', Model);
    handles       = guidata(fig);
    handles.Model = Model;

    % HandleVisibility='callback' means MATLAB will not make this figure the
    % CURRENT one from outside a callback -- so axes(handles.axes_axonDist) does
    % not take, and the bar/plot inside axons_setup and plotPacking open a brand
    % new Figure 1 and draw there instead. The window comes up with both packing
    % plots empty and no error anywhere.
    %
    % GUIDE never hit this because its opening function ran inside gui_mainfcn,
    % which is a callback context. This one is reachable from the command line
    % and from a test. Lift the restriction for the duration of the population
    % and put it back, so `findall`-only access is still what the window ships.
    restoreVisibility = onCleanup(@() set(fig, 'HandleVisibility', 'callback'));
    set(fig, 'HandleVisibility', 'on');

    % Everything is bigger on Windows and Linux. Kept as it was, which is also
    % why the labels clip on macOS -- see the note at the top of this file.
    if ~ismac
        set(findall(fig, 'Type', 'uicontrol'), 'FontSize', 7);
    end

    savedPacks = dir(fullfile(fileparts(which('Sim_MonteCarlo_Diffusion_GUI.m')), 'savedPacks', '*.mat'));
    set(handles.preset_packing, 'String', {savedPacks.name}, 'Value', 1);

    [axons, packing] = loadPreset(handles);
    handles.axonpacking.axons   = axons;
    handles.axonpacking.packing = packing;

    k = 1;
    [FVF, FR, MVF, AVF] = compute_statistics(axons.d{k}/2, axons.Delta{k}, packing.final_positions{k}, [], axons.g_ratio{k});
    set(handles.tableVolumes, 'Data', [FVF; FR; MVF; AVF])

    % Each of these writes its slider's value into its own label.
    slider_Naxons_Callback(handles.slider_Naxons, [], handles)
    slider_dvar_Callback(handles.slider_dvar, [], handles)
    slider_dmean_Callback(handles.slider_dmean, [], handles)
    slider_gap_Callback(handles.slider_gap, [], handles)
    slider_trans_Callback(handles.slider_trans, [], handles)
    slider_numelparticle_Callback(handles.slider_numelparticle, [], handles)
    slider_Dcoef_Callback(handles.slider_Dcoef, [], handles)

    handles.opened = 1;
    guidata(fig, handles);
    drawnow;
end

% ----------------------------------------------------------------------------
% --- Executes on button press in SimMCdiffUpdate.
function SimMCdiffUpdate_Callback(hObject, eventdata, handles) %#ok<INUSL>
set(findall(groot,'Type','figure','Name','SimMCdiff'),'pointer', 'watch'); drawnow;
pointer_restore = onCleanup(@() set(findall(groot,'Type','figure','Name','SimMCdiff'),'pointer', 'arrow')); %#ok<NASGU>

MonteCarloSim(handles, handles.axonpacking.axons, handles.axonpacking.packing)

drawnow;
end

function slider_gap_Callback(hObject, eventdata, handles) %#ok<INUSL>
set(handles.text_gap,'String', ['Gap between axons: ' num2str(get(hObject,'Value')) 'um'])
end

function slider_dvar_Callback(hObject, eventdata, handles) %#ok<INUSL>
update_axonSetup(handles);
set(handles.text_dvar,'String', ['Diameter variance: ' num2str(get(hObject,'Value')) 'um'])
end

function slider_dmean_Callback(hObject, eventdata, handles) %#ok<INUSL>
update_axonSetup(handles);
set(handles.text_dmean,'String', ['mean diameter: ' num2str(get(hObject,'Value')) 'um'])
end

function slider_Naxons_Callback(hObject, eventdata, handles) %#ok<INUSL>
update_axonSetup(handles);
set(handles.text_Naxons,'String', ['# axons: ' num2str(round(get(hObject,'Value')))])
end

function [d, x0, side, axons] = update_axonSetup(handles)
k=1;
axons.N{k}      = round(get(handles.slider_Naxons,'Value'));
axons.d_mean{k} = round(get(handles.slider_dmean,'Value')*10)/10;
set(handles.slider_dmean,'Value',axons.d_mean{k})
axons.d_var{k}  = round(get(handles.slider_dvar,'Value')*10)/10;
set(handles.slider_dvar,'Value',axons.d_var{k});
axons.Delta{k}  = get(handles.slider_gap,'Value');
axons.threshold_high{k} = 20;
axons.threshold_low{k}  = .1;
[d, x0, side] = axons_setup(axons,'gamma', k, handles.axes_axonDist);
if ~ismac, set(handles.axes_axonDist,'FontSize',7); end
end

function run_pack_Callback(hObject, eventdata, handles) %#ok<INUSL>
k=1;
[d, x0, side, axons] = update_axonSetup(handles);

axons.d{k} = d;
axons.g_ratio{k} = compute_gratio(d);

% packing process of the axons
iter_max = 10000;
iter_fvf = iter_max/10;
[final_positions, final_overlap, fvf_historic] = process_packing(x0, d/2, axons.Delta{k}, side, iter_max, iter_fvf);

% store packing results
% main results
packing.initial_positions{k}    = reshape(x0,2,length(x0)/2);
packing.final_positions{k}      = final_positions;
% secondary results
packing.final_overlap{k}        = final_overlap;
packing.FVF_historic{k}         = fvf_historic;
packing.iter_max{k}             = iter_max;

% Statistics from the packing
[FVF, FR, MVF, AVF] = compute_statistics(axons.d{k}/2, axons.Delta{k}, packing.final_positions{k}, side, axons.g_ratio{k});
set(handles.tableVolumes,'Data',[FVF; FR; MVF; AVF])

if ishandle(201), close(201); end
plotPacking(handles,axons,packing)
handles.axonpacking.axons = axons;
handles.axonpacking.packing = packing;

guidata(handles.Simu, handles);
end

function save_pack_Callback(hObject, eventdata, handles) %#ok<INUSL>
axons   = handles.axonpacking.axons; %#ok<NASGU>
packing = handles.axonpacking.packing; %#ok<NASGU>
fname = sprintf('pack_d%.1fvar%.1fgap%.1f.mat',handles.axonpacking.axons.d_mean{1}, ...
    handles.axonpacking.axons.d_var{1},handles.axonpacking.axons.Delta{1});
fname = fullfile(fileparts(which('Sim_MonteCarlo_Diffusion_GUI.m')),'savedPacks',fname);
[fname, path] = uiputfile('*.mat','Save Packing as...',fname);
if fname
    save(fullfile(path,fname),'axons','packing')
    savedPacks = get(handles.preset_packing,'String');
    set(handles.preset_packing,'String',unique([savedPacks; {fname}]));
    savedPacks = get(handles.preset_packing,'String');
    set(handles.preset_packing,'Value',length(savedPacks));
end
end

function preset_packing_Callback(hObject, eventdata, handles) %#ok<INUSL>
[axons, packing] = loadPreset(handles);
handles.axonpacking.axons = axons;
handles.axonpacking.packing = packing;
k=1;
[FVF, FR, MVF, AVF] = compute_statistics(axons.d{k}/2, axons.Delta{k}, packing.final_positions{k}, [], axons.g_ratio{k});
set(handles.tableVolumes,'Data',[FVF; FR; MVF; AVF])

guidata(handles.Simu, handles);
end

function [axons, packing] = loadPreset(handles)
file = get(handles.preset_packing,'String');
loaded = load(file{get(handles.preset_packing,'Value')});
axons   = loaded.axons;
packing = loaded.packing;
axons_setup(axons,'gamma', 1, handles.axes_axonDist);
if ~ismac, set(handles.axes_axonDist,'FontSize',7); end
plotPacking(handles,axons,packing)
end

function plotPacking(handles,axons,packing)
% plot disks
numelobj = size(packing.final_positions{1},2);
cen = packing.final_positions{1}'; cen=cen(:,[2 1]); cen=cen-repmat([mean(cen(:,1)) mean(cen(:,2))],[size(cen,1) 1]); % center position of the cells
cen = [cen, zeros(numelobj,1)];

% Radius of the "cells"
R = [axons.d{1}.*axons.g_ratio{1} axons.d{1}]/2; % internal / external diameter in um
R = R(:,2); %use external radius only.

t = linspace(0,2*pi);

axes(handles.axes_axonPack)
hold off
for k =1:size(R,1)
    plot(R(k,1)*cos(t)+cen(k,1), R(k)*sin(t)+cen(k,2),'b','linewidth',1);
    hold on
end
hold off
axis equal tight
xlabel x(\mum)
ylabel y(\mum)

if ~ismac, set(handles.axes_axonPack,'FontSize',7); end
end

function MonteCarloSim(handles, axons, packing)

% Read updated Model
Model_new = getappdata(0,'Model');
if ~isempty(Model_new) && strcmp(class(Model_new),class(handles.Model))
    handles.Model = Model_new;
end

% Draw into the window's own axes. This was axes(handles.uipanel12), which
% creates a NEW axes in that panel on every press and stacks them.
axes(handles.SimMCdiff);
cla(handles.SimMCdiff);

% Read parameters
numelparticle = round(get(handles.slider_numelparticle,'Value'));

trans_mean = get(handles.slider_trans,'Value'); % mean probability of penetrating the cell walls [0-1]

D = get(handles.slider_Dcoef,'Value'); % Diffusion coefficient

handles.Model.Sim_MonteCarlo_Diffusion(numelparticle, trans_mean, D, packing, axons);
end

function slider_trans_Callback(hObject, eventdata, handles) %#ok<INUSL>
set(handles.text_trans,'String', ['Permeability: ' num2str(get(hObject,'Value'))])
end

function slider_numelparticle_Callback(hObject, eventdata, handles) %#ok<INUSL>
set(hObject,'Value',round(get(hObject,'Value')))
set(handles.text_numelparticle,'String', ['Number of particles: ' num2str(get(hObject,'Value'))])
end

function slider_Dcoef_Callback(hObject, eventdata, handles) %#ok<INUSL>
D = get(hObject,'Value');
set(handles.text_Dcoef,'String', sprintf('Diffusion coefficient: \n\tD = %.2gx 10-3 mm2/sec',D))
set(handles.text_Step,'String', sprintf('steptime = %.1g [ms]\nstepflight = %.1g [um]\n(stepflight^2 = 4*D*steptime)',0.5,sqrt(4*D*.5)))
end
