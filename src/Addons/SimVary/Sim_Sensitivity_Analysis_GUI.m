function varargout = Sim_Sensitivity_Analysis_GUI(Model)
%SIM_SENSITIVITY_ANALYSIS_GUI  Vary each parameter and see what the fit does.
%
%   Sim_Sensitivity_Analysis_GUI(Model)       open the window for a model
%   fig = Sim_Sensitivity_Analysis_GUI(Model) ...and return its figure handle
%
%   Sweeps the parameters ticked in the table between their Min and Max, fits at
%   each step, and plots any result field against any parameter.
%
%   Built in code -- no .fig, no gui_mainfcn. It stays a LEGACY figure: the
%   opening path calls axes(handles.SimVaryAxe) and SimVaryPlot draws with
%   errorbar into gca. See docs/adr/0001-gui-migration.md, F2.
%
%   Every rectangle in this window was already normalized in the .fig, so the
%   geometry below is the .fig's, digit for digit.
%
%   See also: Sim_Sensitivity_Analysis, SimVaryPlot, Test/GUI/tSimWindows.m
%
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Francis Cabana, 2016. Rebuilt off GUIDE in Stage F2.
% ----------------------------------------------------------------------------------------------------

    % This is the only one of the five with an Octave guard, and it is kept: the
    % file is on the path there even though the GUI is not available.
    if moxunit_util_platform_is_octave
        warndlg('Graphical user interface not available on octave... use command lines instead');
        return
    end

    NAME = 'Sensitivity Analysis';

    if nargin < 1 || isempty(Model)
        Model = getappdata(0, 'Model');
    end
    if isempty(Model)
        error('qMRLab:Sim:NoModel', ...
            'No model to analyse. Pass one, or open qMRLab first.');
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
        'Position',         [644 100 866 946], ...
        'Color',            qmrlabUIColor('viewerChrome'), ...
        'MenuBar',          'none', ...
        'ToolBar',          'figure', ...
        'NumberTitle',      'off', ...
        'IntegerHandle',    'off', ...
        'Resize',           'on', ...
        'HandleVisibility', 'callback', ...
        'Visible',          'off');
    movegui(fig, 'onscreen');   % the .fig's own y was -273, i.e. off the screen

    handles        = struct();
    handles.Simu   = fig;
    handles.output = fig;

    % ---------------------------------------------------------------- top half
    handles.uipanel9 = uipanel( ...
        'Parent',     fig, ...
        'Tag',        'uipanel9', ...
        'Title',      'Parameters variation', ...
        'Units',      'normalized', ...
        'Position',   [0.0161663 0.5074 0.952656 0.491543], ...
        'FontSize',   10, ...
        'BorderType', 'none');

    % Column 1 holds the parameter NAMES and is not editable; column 2 is the
    % Vary checkbox. SimVaryUpdate reads them back positionally into a struct
    % with fields xnames/fx/st/lb/ub, so the order is the contract.
    handles.SimVaryOptTable = uitable( ...
        'Parent',         handles.uipanel9, ...
        'Tag',            'SimVaryOptTable', ...
        'Units',          'normalized', ...
        'Position',       [0.22303 0.0470914 0.752727 0.919668], ...
        'ColumnName',     {'Variable', 'Vary', 'Nominal', 'Min', 'Max'}, ...
        'ColumnFormat',   {[], 'logical', [], 'numeric', 'numeric'}, ...
        'ColumnEditable', [false true true true true], ...
        'ColumnWidth',    {90, 70, 90, 90, 90}, ...
        'RowName',        {});

    handles.Save = uicontrol( ...
        'Parent',   handles.uipanel9, ...
        'Style',    'pushbutton', ...
        'Tag',      'Save', ...
        'String',   'Save', ...
        'Units',    'normalized', ...
        'Position', [0.0121212 0.891967 0.192727 0.0914127], ...
        'Callback', @(src, ~) Save_Callback(src, [], guidata(src)));

    handles.Load = uicontrol( ...
        'Parent',   handles.uipanel9, ...
        'Style',    'pushbutton', ...
        'Tag',      'Load', ...
        'String',   'Load', ...
        'Units',    'normalized', ...
        'Position', [0.0121212 0.795014 0.191515 0.0914127], ...
        'Callback', @(src, ~) Load_Callback(src, [], guidata(src)));

    handles.OptionsPanel = uipanel( ...
        'Parent',   handles.uipanel9, ...
        'Tag',      'OptionsPanel', ...
        'Title',    'Options', ...
        'Units',    'normalized', ...
        'Position', [0.0109091 0.0581717 0.193939 0.722992]);

    % ------------------------------------------------------------- bottom half
    handles.uipanel10 = uipanel( ...
        'Parent',     fig, ...
        'Tag',        'uipanel10', ...
        'Title',      'Plot Results', ...
        'Units',      'normalized', ...
        'Position',   [0.0161663 -0.00105708 0.952656 0.489429], ...
        'FontSize',   10, ...
        'BorderType', 'none');

    handles.SimVaryAxe = axes( ...
        'Parent',   handles.uipanel10, ...
        'Tag',      'SimVaryAxe', ...
        'Units',    'normalized', ...
        'Position', [0.115152 0.130243 0.86303 0.763797], ...
        'Color',    [1 1 1]);

    handles.text14 = uicontrol('Parent', handles.uipanel10, 'Style', 'text', ...
        'Tag', 'text14', 'String', 'x axis:', 'Units', 'normalized', ...
        'Position', [0.0375758 0.933775 0.08 0.0463576]);
    handles.text15 = uicontrol('Parent', handles.uipanel10, 'Style', 'text', ...
        'Tag', 'text15', 'String', 'y axis:', 'Units', 'normalized', ...
        'Position', [0.349091 0.933775 0.08 0.0441501]);

    handles.SimVaryPlotX = uicontrol( ...
        'Parent',   handles.uipanel10, ...
        'Style',    'popupmenu', ...
        'Tag',      'SimVaryPlotX', ...
        'String',   {' '}, ...
        'Units',    'normalized', ...
        'Position', [0.11677 0.940039 0.193789 0.0522244], ...
        'Callback', @(src, ~) SimVaryPlotX_Callback(src, [], guidata(src)));

    handles.SimVaryPlotY = uicontrol( ...
        'Parent',   handles.uipanel10, ...
        'Style',    'popupmenu', ...
        'Tag',      'SimVaryPlotY', ...
        'String',   {' '}, ...
        'Units',    'normalized', ...
        'Position', [0.429688 0.940367 0.195312 0.0458716], ...
        'Callback', @(src, ~) SimVaryPlotY_Callback(src, [], guidata(src)));

    if ispc   % the .fig carried this as two identical CreateFcns
        set([handles.SimVaryPlotX handles.SimVaryPlotY], 'BackgroundColor', 'white');
    end

    handles.SimVaryUpdate = uicontrol( ...
        'Parent',          handles.uipanel10, ...
        'Style',           'pushbutton', ...
        'Tag',             'SimVaryUpdate', ...
        'String',          'Update', ...
        'Units',           'normalized', ...
        'Position',        [0.761719 0.933486 0.214844 0.0527523], ...
        'FontSize',        10, ...
        'FontWeight',      'bold', ...
        'BackgroundColor', qmrlabUIColor('accent'), ...
        'ForegroundColor', qmrlabUIColor('onTheAccent'), ...
        'Callback',        @(src, ~) SimVaryUpdate_Callback(src, [], guidata(src)));

    guidata(fig, handles);
    fig.Visible = 'on';
end

% ----------------------------------------------------------------------------
function showModel(fig, Model)
%SHOWMODEL  Point the window at a model. Runs on EVERY open.
    setappdata(0, 'Model', Model);
    handles       = guidata(fig);
    handles.Model = Model;

    axes(handles.SimVaryAxe);

    % Verbatim from the GUIDE opening function, including the order: columns 4
    % and 5 are filled BEFORE column 3, and the two size() tests below read that
    % as "were there bounds?". Rewriting it to be clearer would change which
    % branch a model without bounds takes.
    Nparam = length(Model.xnames);
    FitOptTable(:,1) = Model.xnames(:);
    if isprop(Model,'fx') && ~isempty(Model.fx)
        FitOptTable(:,2) = mat2cell(~logical(Model.fx(:)),ones(Nparam,1));
    end
    if isprop(Model,'ub') && ~isempty(Model.ub)
        FitOptTable(:,4) = mat2cell(Model.lb(:),ones(Nparam,1));
        FitOptTable(:,5) = mat2cell(Model.ub(:),ones(Nparam,1));
    end
    if isprop(Model,'st') && ~isempty(Model.st)
        FitOptTable(:,3) = mat2cell(Model.st(:),ones(Nparam,1));
    elseif size(FitOptTable,2)==5
        FitOptTable(:,3) = mat2cell(mean(cat(2,Model.lb(:),Model.ub(:)),2),ones(Nparam,1));
    else
        FitOptTable(:,3) = mat2cell(ones(Nparam,1),ones(Nparam,1));
    end
    if size(FitOptTable,2)<5
        FitOptTable(:,4) = mat2cell(cell2mat(FitOptTable(:,3))/2,ones(Nparam,1));
        FitOptTable(:,5) = mat2cell(cell2mat(FitOptTable(:,3))*2,ones(Nparam,1));
    end
    set(handles.SimVaryOptTable,'Data',FitOptTable)

    % The .fig ships both popups with an EMPTY String; without this the window
    % opens with two blank selectors and no way to plot anything.
    set(handles.SimVaryPlotX,'String',Model.xnames(:),'Value',1)
    set(handles.SimVaryPlotY,'String',Model.xnames(:),'Value',1)

    delete(allchild(handles.OptionsPanel));
    if isprop(Model,'Sim_Single_Voxel_Curve_buttons')
        opts = Model.Sim_Single_Voxel_Curve_buttons;
    else
        opts = {'SNR',50};
    end
    if isprop(Model,'Sim_Sensitivity_Analysis_buttons')
        opts = cat(2,opts,Model.Sim_Sensitivity_Analysis_buttons);
    else
        opts = cat(2,opts,{'# of run',20});
    end
    handles.options = GenerateButtonsWithPanels(opts,handles.OptionsPanel);

    ff = fieldnames(handles.options);
    for ii = 1:numel(ff)
        h = handles.options.(ff{ii});
        if isgraphics(h) && strcmp(get(h,'Style'),'togglebutton')
            set(h,'Callback',@(src,~) ModelSimOptions_Callback(guidata(src)));
        end
    end

    handles.opened = 1;
    guidata(fig, handles);
    drawnow;
end

% ----------------------------------------------------------------------------
% --- Executes on button press in SimVaryUpdate.
function SimVaryUpdate_Callback(hObject, eventdata, handles) %#ok<INUSL>
Model_new = getappdata(0,'Model');
if ~isempty(Model_new) && strcmp(class(Model_new),class(handles.Model))
    handles.Model = Model_new;
end
FitOptTable = get(handles.SimVaryOptTable,'Data'); FitOptTable(:,2)=mat2cell(~[FitOptTable{:,2}]',ones(size(FitOptTable,1),1), 1);
FitOptTable = cell2struct(FitOptTable,{'xnames','fx','st','lb','ub'},2);
Opts = button_handle2opts(handles.options);
handles.SimVaryResults = handles.Model.Sim_Sensitivity_Analysis(FitOptTable,Opts);
SetSimVaryResults(handles)
guidata(handles.Simu, handles);
end

% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles) %#ok<INUSL>
if isfield(handles,'SimVaryResults')
    Method = class(handles.Model);
    [FileName,PathName] = uiputfile([Method '_SimResults.mat']);
    if PathName == 0, return; end
    SimVaryResults = handles.SimVaryResults; %#ok<NASGU>
    save(fullfile(PathName,FileName),'SimVaryResults')
end
end

function Load_Callback(hObject, eventdata, handles) %#ok<INUSL>
Method = class(handles.Model);
[FileName,PathName] = uigetfile([Method '_SimResults.mat']);
if PathName == 0, return; end
loaded = load(fullfile(PathName,FileName));
handles.SimVaryResults = loaded.SimVaryResults;
SetSimVaryResults(handles)
guidata(handles.Simu, handles);
end

% --- Executes on button press in Options panel.
function ModelSimOptions_Callback(handles)
xtable = get(handles.SimVaryOptTable,'Data');
x=cell2mat(xtable(~cellfun(@isempty,xtable(:,3)),3))';
xnew = SimOpt(handles.Model,x,button_handle2opts(handles.options));
if ~isempty(xnew) % update the ParamTable in the GUI
    Nparam = length(handles.Model.xnames);
    xtable(1:Nparam,3) = mat2cell(xnew',ones(Nparam,1));
    set(handles.SimVaryOptTable,'Data',xtable);
end
end

function SetSimVaryResults(handles)
ff=fieldnames(handles.SimVaryResults);
set(handles.SimVaryPlotX,'String',ff,'Value',1);
ff=fieldnames(handles.SimVaryResults.(ff{1}));
set(handles.SimVaryPlotY,'String',ff(~ismember(ff,{'x','fit'})),'Value',1);
SimVaryPlotResults(handles)
end

% --- Executes on selection change in SimVaryPlotX.
function SimVaryPlotX_Callback(hObject, eventdata, handles) %#ok<INUSL>
SimVaryPlotResults(handles)
end

% --- Executes on selection change in SimVaryPlotY.
function SimVaryPlotY_Callback(hObject, eventdata, handles) %#ok<INUSL>
SimVaryPlotResults(handles)
end

function SimVaryPlotResults(handles)
if isfield(handles,'SimVaryResults')
    Xaxis = get(handles.SimVaryPlotX,'String'); Xaxis = Xaxis{get(handles.SimVaryPlotX,'Value')};
    Yaxis = get(handles.SimVaryPlotY,'String'); Yaxis = Yaxis{get(handles.SimVaryPlotY,'Value')};
    SimVaryPlot(handles.SimVaryResults,Xaxis,Yaxis)
end
end
