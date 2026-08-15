function varargout = Sim_Optimize_Protocol_GUI(Model)
%SIM_OPTIMIZE_PROTOCOL_GUI  Optimize a protocol against fitting stability.
%
%   Sim_Optimize_Protocol_GUI(Model)       open the window for a model
%   fig = Sim_Optimize_Protocol_GUI(Model) ...and return its figure handle
%
% Usage:
%   Click Update to run the optimization. When it finishes, a Single Voxel Curve
%   simulation runs on the optimized protocol. Save writes the protocol to text.
%
% Options:
%   # of volumes      Number of volumes in the optimized protocol
%   Population size   Population size
%   # of migrations   Iterations before the optimizer stops (interruptible)
%
% Description:
%   Uses the Cramer-Rao Lower Bound as the objective function:
%   <a href="matlab: web('https://en.wikipedia.org/wiki/Cramer-Rao_bound')">Wikipedia</a>
%   Based on: Alexander, D.C., 2008. A general framework for experiment design in
%   diffusion MRI and its application in measuring direct tissue-microstructure
%   features. Magn. Reson. Med. 60, 439-448.
%
%   Built in code -- no .fig, no gui_mainfcn. It stays a LEGACY figure because
%   SimOptProtUpdate_Callback calls axes(handles.SimCurveAxe) before plotProt /
%   Sim_Single_Voxel_Curve, and plotModel takes no axes handle. See the F2 note in
%   docs/adr/0001-gui-migration.md.
%
%   WHY THE GEOMETRY IS NOT COPIED VERBATIM FROM THE .fig
%
%   Four of its components were positioned in CHARACTER units -- OptionsPanel,
%   ParamTable, text19 and SimCurveAxe. A character is a font metric, so those
%   rectangles change size with the system font, and that is not a theory: CI
%   reported ParamTable outside its panel by ~15 px on the Linux runner while it
%   fitted on macOS. They are normalized here, computed from the rendered pixel
%   geometry at the design size, so the layout is the same proportion everywhere.
%
%   Two defects visible in Test/GUI/evidence/before_F2/charmed_SimOptProt.png are
%   fixed at the same time, because the conversion had to touch those rectangles
%   anyway:
%     - "Tissue parameters assumed for the optimization:" sat at y = 1.001 of its
%       panel -- above the drawable area -- and was clipped to a sliver.
%     - Save overlapped the top of the Options panel.
%
%   See also: Sim_Optimize_Protocol, Test/GUI/tSimWindows.m
%
% ----------------------------------------------------------------------------------------------------
% Written by: Tanguy Duval, 2016. Rebuilt off GUIDE in Stage F2.
% ----------------------------------------------------------------------------------------------------

    NAME = 'SimOptProt';

    if nargin < 1 || isempty(Model)
        Model = getappdata(0, 'Model');
    end
    if isempty(Model)
        error('qMRLab:Sim:NoModel', ...
            'No model to optimize. Pass one, or open qMRLab first.');
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

    % ---------------------------------------------------------------- top half
    handles.uipanel9 = uipanel( ...
        'Parent',     fig, ...
        'Tag',        'uipanel9', ...
        'Title',      'Optimization parameters', ...
        'Units',      'normalized', ...
        'Position',   [0.0151692 0.693928 0.952159 0.304833], ...
        'FontSize',   10, ...
        'BorderType', 'none');

    handles.Save = uicontrol( ...
        'Parent',     handles.uipanel9, ...
        'Style',      'pushbutton', ...
        'Tag',        'Save', ...
        'String',     'Save', ...
        'Units',      'normalized', ...
        'Position',   [0.030637 0.865 0.158088 0.115], ...
        'FontSize',   10, ...
        'FontWeight', 'bold', ...
        'Callback',   @(src, ~) Save_Callback(src, [], guidata(src)));

    % Was 0.828 tall with its top at 0.892, which put it under the Save button.
    handles.OptionsPanel = uipanel( ...
        'Parent',   handles.uipanel9, ...
        'Tag',      'OptionsPanel', ...
        'Title',    'Options', ...
        'Units',    'normalized', ...
        'Position', [0.011029 0.064 0.242647 0.780], ...
        'FontSize', 10);

    % Was at y = 1.001 in character units: outside the panel, clipped to a sliver.
    handles.text19 = uicontrol( ...
        'Parent',              handles.uipanel9, ...
        'Style',               'text', ...
        'Tag',                 'text19', ...
        'String',              'Tissue parameters assumed for the optimization:', ...
        'Units',               'normalized', ...
        'Position',            [0.269608 0.878 0.517647 0.075], ...
        'FontSize',            10, ...
        'HorizontalAlignment', 'left');

    % ColumnName and ColumnEditable are set per model in showModel: this table is
    % headed by the PARAMETER NAMES and holds a single row of values, unlike the
    % other Sim windows, because GenerateButtons drives it rather than
    % GenerateButtonsWithPanels.
    handles.ParamTable = uitable( ...
        'Parent',   handles.uipanel9, ...
        'Tag',      'ParamTable', ...
        'Units',    'normalized', ...
        'Position', [0.269608 0.0728 0.713235 0.790]);

    % ------------------------------------------------------------- bottom half
    handles.uipanel12 = uipanel( ...
        'Parent',        fig, ...
        'Tag',           'uipanel12', ...
        'Title',         'Plot Results', ...
        'TitlePosition', 'lefttop', ...
        'Units',         'normalized', ...
        'Position',      [0.0151692 0.0173482 0.955 0.666667], ...
        'FontSize',      10, ...
        'BorderType',    'none');

    handles.SimCurveAxe = axes( ...
        'Parent',   handles.uipanel12, ...
        'Tag',      'SimCurveAxe', ...
        'Units',    'normalized', ...
        'Position', [0.0821 0.1164 0.8721 0.8546], ...
        'FontSize', 10, ...
        'Color',    [1 1 1]);

    handles.SimOptProtUpdate = uicontrol( ...
        'Parent',          handles.uipanel12, ...
        'Style',           'pushbutton', ...
        'Tag',             'SimOptProtUpdate', ...
        'String',          'Update', ...
        'Units',           'normalized', ...
        'Position',        [0.808219 0.93463 0.170254 0.0501509], ...
        'FontSize',        10, ...
        'FontWeight',      'bold', ...
        'BackgroundColor', qmrlabUIColor('accent'), ...
        'ForegroundColor', qmrlabUIColor('onTheAccent'), ...
        'Callback',        @(src, ~) SimOptProtUpdate_Callback(src, [], guidata(src)));

    % The .fig carried a help button on its own toolbar, alongside MATLAB's own
    % legend and plot-edit tools. Keep it -- with the menu bar off it is the only
    % route to this window's documentation -- but APPEND it to the standard
    % toolbar rather than creating a second one, which cost a whole toolbar row.
    drawnow;   % the standard toolbar is not there to be found until the figure is
    bar = findall(fig, 'Type', 'uitoolbar');
    if isempty(bar)
        bar = uitoolbar(fig, 'Tag', 'uitoolbar1');
    end
    handles.uitoolbar1 = bar(1);
    handles.helpbutton = uipushtool(handles.uitoolbar1, ...
        'Tag',              'helpbutton', ...
        'Separator',        'on', ...
        'TooltipString',    'Help', ...
        'ClickedCallback',  @(~,~) doc('Sim_Optimize_Protocol_GUI'));
    try
        icon = fullfile(matlabroot, 'toolbox', 'matlab', 'icons', 'helpicon.gif');
        [cdata, map] = imread(icon);
        handles.helpbutton.CData = ind2rgb(cdata, map);
    catch
        % No icon shipped with this release; the tooltip still says what it does.
    end

    guidata(fig, handles);
    fig.Visible = 'on';
end

% ----------------------------------------------------------------------------
function showModel(fig, Model)
%SHOWMODEL  Point the window at a model. Runs on EVERY open, so that reopening
%   on another method does not leave the previous model's parameters on screen.
    setappdata(0, 'Model', Model);
    handles       = guidata(fig);
    handles.Model = Model;

    Nparam = numel(Model.xnames);
    FitOptTable = cell(1, Nparam);
    if isprop(Model, 'st') && ~isempty(Model.st)
        FitOptTable(1,:) = num2cell(Model.st(:)');
    elseif isprop(Model, 'ub') && ~isempty(Model.ub) && ...
           isprop(Model, 'lb') && ~isempty(Model.lb)
        FitOptTable(1,:) = num2cell((Model.ub(:)' - Model.lb(:)') / 2);
    end
    set(handles.ParamTable, 'ColumnName', Model.xnames, ...
                            'ColumnEditable', true(1, Nparam), ...
                            'Data', FitOptTable);

    % GenerateButtons, NOT GenerateButtonsWithPanels: a different generator with
    % different handle naming -- it emits no *lbl companions and does not strip
    % the ## / ** prefixes. tDSL pins the other one.
    delete(allchild(handles.OptionsPanel));
    opts = {};
    if isprop(Model, 'Sim_Optimize_Protocol_buttons')
        opts = cat(2, opts, Model.Sim_Optimize_Protocol_buttons);
    end
    handles.options = GenerateButtons(opts, handles.OptionsPanel, .15);

    handles.opened = 1;
    guidata(fig, handles);
    drawnow;
end

% ----------------------------------------------------------------------------
% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles) %#ok<INUSL>
if isfield(handles,'ProtOpt')
    Model = handles.Model;
    Method = class(Model);
    [FileName,PathName] = uiputfile([Method '_ProtocolOptim.txt']);
    if PathName == 0, return; end
    fid = fopen(fullfile(PathName,FileName),'w');
    if iscell(Model.Prot.(Model.MRIinputs{1}).Format)
    Model.Prot.(Model.MRIinputs{1}).Format{1}=['# ' Model.Prot.(Model.MRIinputs{1}).Format{1}];
    else
        format = Model.Prot.(Model.MRIinputs{1}).Format;
        Model.Prot.(Model.MRIinputs{1}).Format = cell(1,1);
        Model.Prot.(Model.MRIinputs{1}).Format{1}=['# ' format];
    end
    fprintf(fid, '%-15s ',Model.Prot.(Model.MRIinputs{1}).Format{:});
    for i_line=1:size(handles.ProtOpt,1)
        fprintf(fid, '\n');
        fprintf(fid, '%-15.2g ',handles.ProtOpt(i_line,:));
    end
    fclose(fid);
else
    helpdlg('launch the simulation first: click on update button')
end
end

% --- Executes on button press in SimOptProtUpdate.
function SimOptProtUpdate_Callback(hObject, eventdata, handles) %#ok<INUSL>
set(findall(groot,'Type','figure','Name','SimOptProt'),'pointer', 'watch'); drawnow;
pointer_restore = onCleanup(@() set(findall(groot,'Type','figure','Name','SimOptProt'),'pointer', 'arrow')); %#ok<NASGU>

% Read Table
Model_new = getappdata(0,'Model');
if ~isempty(Model_new) && strcmp(class(Model_new),class(handles.Model))
    handles.Model = Model_new;
end
ParamOpt = get(handles.ParamTable,'Data');
Opt = button_handle2opts(handles.options);
if isgraphics(handles.SimCurveAxe)
    axes(handles.SimCurveAxe);
end
xvalues=cell2mat(ParamOpt);
handles.ProtOpt = handles.Model.Sim_Optimize_Protocol(xvalues, Opt);
guidata(handles.Simu, handles);

Model = handles.Model;
Model.Prot.(Model.MRIinputs{1}).Mat = handles.ProtOpt;
Model = Model.UpdateFields();
if ismethod(Model,'plotProt')
    Model.plotProt;
else
    Opt = button2opts(Model.Sim_Single_Voxel_Curve_buttons);
    Model.Sim_Single_Voxel_Curve(xvalues(1,:),Opt,1);
end
drawnow;
end
