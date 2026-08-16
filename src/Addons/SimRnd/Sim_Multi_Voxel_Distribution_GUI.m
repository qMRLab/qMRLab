function varargout = Sim_Multi_Voxel_Distribution_GUI(Model)
%SIM_MULTI_VOXEL_DISTRIBUTION_GUI  Fit many voxels drawn from parameter distributions.
%
%   Sim_Multi_Voxel_Distribution_GUI(Model)       open the window for a model
%   fig = Sim_Multi_Voxel_Distribution_GUI(Model) ...and return its figure handle
%
%   Draws NumVoxels parameter sets from the per-parameter Mean/Std/Min/Max in the
%   table, simulates and fits each, and plots the result eight different ways.
%
%   Built in code -- no .fig, no gui_mainfcn. It stays a LEGACY figure:
%   SimRndUpdatePopUp calls axes(handles.SimRndAxe) and SimRndPlotResults draws
%   with subplot, neither of which works in a uifigure. See docs/adr/0001, F2.
%
%   OptionsPanel was the last component here still positioned in CHARACTER units;
%   it is normalized now, for the reason spelled out in Sim_Optimize_Protocol_GUI:
%   a character is a font metric, so a rectangle expressed in characters is a
%   different size on every machine.
%
%   See also: Sim_Multi_Voxel_Distribution, SimRndPlotResults, Test/GUI/tSimWindows.m
%
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Francis Cabana, 2016. Rebuilt off GUIDE in Stage F2.
% ----------------------------------------------------------------------------------------------------

    NAME = 'Multi Voxel Distribution';

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
        'Position',         [644 100 855 872], ...
        'Color',            qmrlabUIColor('viewerChrome'), ...
        'MenuBar',          'none', ...
        'ToolBar',          'figure', ...
        'NumberTitle',      'off', ...
        'IntegerHandle',    'off', ...
        'Resize',           'off', ...
        'HandleVisibility', 'callback', ...
        'Visible',          'off');
    movegui(fig, 'onscreen');   % the .fig's own y was -199, i.e. off the screen

    handles        = struct();
    handles.Simu   = fig;
    handles.output = fig;

    % ---------------------------------------------------------------- top half
    handles.uipanel9 = uipanel( ...
        'Parent',     fig, ...
        'Tag',        'uipanel9', ...
        'Title',      'Parameters variation', ...
        'Units',      'normalized', ...
        'Position',   [0.0152047 0.494266 0.978947 0.504587], ...
        'FontSize',   10, ...
        'BorderType', 'none');

    % Column 1 is LOGICAL -- the Vary checkboxes -- and the parameter names are in
    % RowName, not in a column. The other Sim tables are the other way round.
    handles.SimRndVaryOptTable = uitable( ...
        'Parent',         handles.uipanel9, ...
        'Tag',            'SimRndVaryOptTable', ...
        'Units',          'normalized', ...
        'Position',       [0.303465 0.0478469 0.67264 0.921053], ...
        'ColumnName',     {'Vary', 'Mean', 'Std', 'Min', 'Max'}, ...
        'ColumnFormat',   {'logical', 'numeric', 'numeric', 'numeric', 'numeric'}, ...
        'ColumnEditable', true(1, 5), ...
        'ColumnWidth',    {70, 90, 90, 90, 90});

    handles.Save = uicontrol( ...
        'Parent',   handles.uipanel9, ...
        'Style',    'pushbutton', ...
        'Tag',      'Save', ...
        'String',   'Save', ...
        'Units',    'normalized', ...
        'Position', [0.0307125 0.892086 0.216216 0.0899281], ...
        'Callback', @(src, ~) Save_Callback(src, [], guidata(src)));

    handles.Load = uicontrol( ...
        'Parent',   handles.uipanel9, ...
        'Style',    'pushbutton', ...
        'Tag',      'Load', ...
        'String',   'Load', ...
        'Units',    'normalized', ...
        'Position', [0.0307125 0.797464 0.216216 0.0899281], ...
        'Callback', @(src, ~) Load_Callback(src, [], guidata(src)));

    % Was [1.28571 0.625 33.5714 20.5625] in CHARACTERS.
    handles.OptionsPanel = uipanel( ...
        'Parent',   handles.uipanel9, ...
        'Tag',      'OptionsPanel', ...
        'Title',    'Options', ...
        'Units',    'normalized', ...
        'Position', [0.01082 0.02309 0.28271 0.75754]);

    % ------------------------------------------------------------- bottom half
    handles.uipanel12 = uipanel( ...
        'Parent',     fig, ...
        'Tag',        'uipanel12', ...
        'Title',      'Plot Results', ...
        'Units',      'normalized', ...
        'Position',   [0.0152047 0 0.978947 0.482798], ...
        'FontSize',   10, ...
        'BorderType', 'none');

    handles.SimRndAxe = axes( ...
        'Parent',   handles.uipanel12, ...
        'Tag',      'SimRndAxe', ...
        'Units',    'normalized', ...
        'Position', [0.0958904 0.0889325 0.882583 0.823196], ...
        'Color',    [1 1 1]);

    handles.text18 = label(handles.uipanel12, 'text18', 'Plot type:', ...
        [0.0136986 0.943749 0.123288 0.0319142]);
    handles.text16 = label(handles.uipanel12, 'text16', 'x axis:', ...
        [0.309198 0.93691 0.0802348 0.0319142]);
    handles.text17 = label(handles.uipanel12, 'text17', 'y axis:', ...
        [0.551859 0.93691 0.0802348 0.0319142]);

    handles.SimRndPlotType = uicontrol( ...
        'Parent',   handles.uipanel12, ...
        'Style',    'popupmenu', ...
        'Tag',      'SimRndPlotType', ...
        'String',   {'Input parameters', 'Fit results', 'Input vs. Fit', 'Error', ...
                     'Pct error', 'RMSE', 'NRMSE', 'MPE'}, ...
        'Units',    'normalized', ...
        'Position', [0.11546 0.93691 0.164384 0.0455917], ...
        'Callback', @(src, ~) SimRndPlotType_Callback(src, [], guidata(src)));

    handles.SimRndPlotX = uicontrol( ...
        'Parent',   handles.uipanel12, ...
        'Style',    'popupmenu', ...
        'Tag',      'SimRndPlotX', ...
        'String',   {' '}, ...
        'Units',    'normalized', ...
        'Position', [0.386308 0.9375 0.134474 0.0454545], ...
        'Callback', @(src, ~) SimRndPlotX_Callback(src, [], guidata(src)));

    handles.SimRndPlotY = uicontrol( ...
        'Parent',   handles.uipanel12, ...
        'Style',    'popupmenu', ...
        'Tag',      'SimRndPlotY', ...
        'String',   {' '}, ...
        'Units',    'normalized', ...
        'Position', [0.624266 0.93691 0.156556 0.0455917], ...
        'Callback', @(src, ~) SimRndPlotY_Callback(src, [], guidata(src)));

    % The .fig carried this as three identical CreateFcns.
    if ispc
        set([handles.SimRndPlotType handles.SimRndPlotX handles.SimRndPlotY], ...
            'BackgroundColor', 'white');
    end

    handles.SimRndVaryUpdate = uicontrol( ...
        'Parent',          handles.uipanel12, ...
        'Style',           'pushbutton', ...
        'Tag',             'SimRndVaryUpdate', ...
        'String',          'Update', ...
        'Units',           'normalized', ...
        'Position',        [0.808219 0.93463 0.170254 0.0501509], ...
        'FontSize',        10, ...
        'FontWeight',      'bold', ...
        'BackgroundColor', qmrlabUIColor('accent'), ...
        'ForegroundColor', qmrlabUIColor('onTheAccent'), ...
        'Callback',        @(src, ~) SimRndVaryUpdate_Callback(src, [], guidata(src)));

    guidata(fig, handles);
    fig.Visible = 'on';
end

function h = label(parent, tag, text, pos)
    h = uicontrol('Parent', parent, 'Style', 'text', 'Tag', tag, ...
                  'String', text, 'Units', 'normalized', 'Position', pos);
end

% ----------------------------------------------------------------------------
function showModel(fig, Model)
%SHOWMODEL  Point the window at a model. Runs on EVERY open.
    setappdata(0, 'Model', Model);
    handles       = guidata(fig);
    handles.Model = Model;

    % Column for column as the GUIDE version filled it, fallbacks included:
    % Vary = ~fx, Mean = st or the midpoint of the bounds, Std = a tenth of the
    % range, Min/Max = the bounds.
    Nparam = numel(Model.xnames);
    FitOptTable = cell(Nparam, 5);
    if isprop(Model, 'fx') && ~isempty(Model.fx)
        FitOptTable(:,1) = num2cell(~logical(Model.fx(:)));
    end
    if isprop(Model, 'st') && ~isempty(Model.st)
        FitOptTable(:,2) = num2cell(Model.st(:));
    elseif isprop(Model, 'ub') && ~isempty(Model.ub)
        FitOptTable(:,2) = num2cell((Model.ub(:) + Model.lb(:)) / 2);
    end
    if isprop(Model, 'ub') && ~isempty(Model.ub)
        FitOptTable(:,3) = num2cell((Model.ub(:) - Model.lb(:)) / 10);
        FitOptTable(:,4) = num2cell(Model.lb(:));
        FitOptTable(:,5) = num2cell(Model.ub(:));
    end
    set(handles.SimRndVaryOptTable, 'RowName', Model.xnames(:), 'Data', FitOptTable);

    set(handles.SimRndPlotX, 'String', Model.xnames(:), 'Value', 1);
    set(handles.SimRndPlotY, 'String', {'Voxels count'}, 'Value', 1);

    delete(allchild(handles.OptionsPanel));
    opts = {'# of voxels', 100};
    if isprop(Model, 'Sim_Single_Voxel_Curve_buttons')
        opts = cat(2, opts, Model.Sim_Single_Voxel_Curve_buttons);
    else
        opts = cat(2, opts, {'SNR', 50});
    end
    handles.options = GenerateButtonsWithPanels(opts, handles.OptionsPanel);

    ff = fieldnames(handles.options);
    for ii = 1:numel(ff)
        h = handles.options.(ff{ii});
        if isgraphics(h) && strcmp(get(h, 'Style'), 'togglebutton')
            set(h, 'Callback', @(src, ~) ModelSimOptions_Callback(guidata(src)));
        end
    end

    handles.opened = 1;
    guidata(fig, handles);
    drawnow;
end

% ----------------------------------------------------------------------------
% --- Executes on button press in SimRndVaryUpdate.
function SimRndVaryUpdate_Callback(hObject, eventdata, handles) %#ok<INUSL>
% Read Table
Model_new = getappdata(0,'Model');
if ~isempty(Model_new) && strcmp(class(Model_new),class(handles.Model))
    handles.Model = Model_new;
end
SimRndOpt = get(handles.SimRndVaryOptTable,'Data'); SimRndOpt(:,1)=mat2cell(~[SimRndOpt{:,1}]',ones(size(SimRndOpt,1),1), 1);
SimRndOpt = cell2struct(SimRndOpt,{'fx','Mean','Std','Min','Max'},2);
[SimRndOpt.xnames] = deal(handles.Model.xnames{:});
Opt = button_handle2opts(handles.options);
handles.RndParam = GetRndParam(SimRndOpt,Opt.Nofvoxels);
handles.SimRndResults = handles.Model.Sim_Multi_Voxel_Distribution(handles.RndParam, Opt);
SimRndPlotResultsgui(handles);
guidata(handles.Simu, handles);
end

% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles) %#ok<INUSL>
if isfield(handles,'SimRndResults')
    Method = class(handles.Model);
    [FileName,PathName] = uiputfile([Method '_SimRndResults.mat']);
    if PathName == 0, return; end
    SimRndResults = handles.SimRndResults;
    RndParam      = handles.RndParam;
    save(fullfile(PathName,FileName),'SimRndResults','RndParam')
end
end

function Load_Callback(hObject, eventdata, handles) %#ok<INUSL>
Method = class(handles.Model);
[FileName,PathName] = uigetfile([Method '_SimResults.mat']);
if PathName == 0, return; end
loaded = load(fullfile(PathName,FileName));
handles.SimRndResults = loaded.SimRndResults;
handles.RndParam      = loaded.RndParam;
SimRndPlotResultsgui(handles)
guidata(handles.Simu, handles);
end

% --- Executes on button press in Options panel.
function ModelSimOptions_Callback(handles)
xtable = get(handles.SimRndVaryOptTable,'Data');
x=cell2mat(xtable(~cellfun(@isempty,xtable(:,3)),3))';
xnew = SimOpt(handles.Model,x,button_handle2opts(handles.options));
if ~isempty(xnew) % update the ParamTable in the GUI
    Nparam = length(handles.Model.xnames);
    xtable(1:Nparam,3) = mat2cell(xnew',ones(Nparam,1));
    set(handles.SimRndVaryOptTable,'Data',xtable);
end
end

function SimRndUpdatePopUp(handles)
axes(handles.SimRndAxe);
colormap('default');
set(handles.SimRndPlotX, 'Value', 1);
set(handles.SimRndPlotY, 'Value', 1);
PlotTypeFields = cellstr(get(handles.SimRndPlotType, 'String'));
PlotType = PlotTypeFields{get(handles.SimRndPlotType, 'Value')};
switch PlotType
    case 'Input parameters'
        XdataFields = fieldnames(handles.RndParam);
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Fit results'
        XdataFields = handles.SimRndResults.fields;
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Input vs. Fit'
        XdataFields = fieldnames(handles.RndParam);
        set(handles.SimRndPlotX, 'String', XdataFields);
        YdataFields = handles.SimRndResults.fields;
        set(handles.SimRndPlotY, 'String', YdataFields);
    case 'Error'
        XdataFields = fieldnames(handles.SimRndResults.Error);
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Pct error'
        XdataFields = fieldnames(handles.SimRndResults.PctError);
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'RMSE'
        set(handles.SimRndPlotX, 'String', 'Parameters');
        set(handles.SimRndPlotY, 'String', 'RMSE');
    case 'NRMSE'
        set(handles.SimRndPlotX, 'String', 'Parameters');
        set(handles.SimRndPlotY, 'String', 'NRMSE');
    case 'MPE'
        set(handles.SimRndPlotX, 'String', 'Parameters');
        set(handles.SimRndPlotY, 'String', 'MPE');
end
guidata(handles.Simu, handles);
end

% --- Executes on selection change in SimRndPlotY.
function SimRndPlotY_Callback(hObject, eventdata, handles) %#ok<INUSL>
SimRndPlotResultsgui(handles);
end

% --- Executes on selection change in SimRndPlotX.
function SimRndPlotX_Callback(hObject, eventdata, handles) %#ok<INUSL>
SimRndPlotResultsgui(handles);
end

% --- Executes on selection change in SimRndPlotType.
function SimRndPlotType_Callback(hObject, eventdata, handles) %#ok<INUSL>
SimRndUpdatePopUp(handles);
SimRndPlotResultsgui(handles);
end

function SimRndPlotResultsgui(handles)
% Nothing to plot until Update has run once.
if ~isfield(handles, 'SimRndResults') || ~isfield(handles, 'RndParam')
    return
end
PlotTypeFields  = cellstr(get(handles.SimRndPlotType, 'String'));
PlotType = PlotTypeFields{get(handles.SimRndPlotType, 'Value')};
XdataFields    =     cellstr(get(handles.SimRndPlotX, 'String'));
Xdata          = XdataFields{get(handles.SimRndPlotX, 'Value')};
YdataFields    =     cellstr(get(handles.SimRndPlotY, 'String'));
Ydata          = YdataFields{get(handles.SimRndPlotY, 'Value')};
SimRndPlotResults(handles.RndParam,handles.SimRndResults,PlotType,Xdata,Ydata);
end

function RndParam = GetRndParam(table,NumVoxels)
n    = NumVoxels;
for ii = 1:length(table)
    if~(table(ii).fx); RndParam.(table(ii).xnames) = min(table(ii).Max, max(table(ii).Min,table(ii).Mean + table(ii).Std*(randn(n,1))));
    else          RndParam.(table(ii).xnames) = table(ii).Mean*(ones(n,1));
    end
end
end
