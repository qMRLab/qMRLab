function varargout = Sim_Single_Voxel_Curve_GUI(Model)
%SIM_SINGLE_VOXEL_CURVE_GUI  Simulate one voxel for a model, fit it, and plot.
%
%   Sim_Single_Voxel_Curve_GUI(Model)       open the window for a model
%   fig = Sim_Single_Voxel_Curve_GUI(Model) ...and return its figure handle
%   Sim_Single_Voxel_Curve_GUI()            use the model in the shared store
%
%   Built in code. There is no .fig and no gui_mainfcn: nothing anywhere called
%   this file with GUIDE's ('CALLBACK', hObject, ...) string form, so the whole
%   dispatch preamble went with the layout file.
%
%   WHY THIS IS A LEGACY figure AND NOT A uifigure
%
%   Decided, not incidental. UpdatePlot_Callback calls axes(handles.SimCurveAxe)
%   and then Sim_Single_Voxel_Curve -> Model.plotModel, which takes no axes handle
%   across 61 subplot and 23 gca sites in 22 model classes. Neither axes(h) nor
%   subplot works in a uifigure, so making this window modern would force an
%   axes-handle refactor through every model class -- breaking every user's
%   plotting script and the Octave/CLI path -- to modernise a window that plots.
%   See docs/adr/0001-gui-migration.md and the plan's Stage F2.
%
%   WHAT THE REST OF qMRLab RELIES ON HERE
%
%   Tag='Simu' on the figure (MainApp.m:1164 tears these windows down by it), the
%   figure Name (the only thing telling the five Sim windows apart), and the
%   handles field names -- other Sim windows reach handles.Simu directly.
%
%   See also: Sim_Single_Voxel_Curve, Test/GUI/tSimWindows.m
%
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Francis Cabana, 2016. Rebuilt off GUIDE in Stage F2.
% ----------------------------------------------------------------------------------------------------

    NAME = 'Single Voxel Curve';

    if nargin < 1 || isempty(Model)
        Model = getappdata(0, 'Model');
    end
    if isempty(Model)
        error('qMRLab:Sim:NoModel', ...
            'No model to simulate. Pass one, or open qMRLab first.');
    end

    % findall, not findobj: the window is HandleVisibility='callback', so findobj
    % cannot see it from anywhere that is not itself a callback.
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
%BUILDWINDOW  The components the .fig used to hold, with its geometry.
%
%   Positions are the .fig's, to the digit, so that the capture in
%   Test/GUI/evidence/before_F2 stays comparable. Two colours deliberately are
%   NOT the .fig's:
%
%     - The figure Color was a hard-coded [0.251 0.251 0.251] that a legacy
%       figure will never theme, and it showed through as dark gaps between the
%       light panels (see the before_F2 PNG). It now follows the viewerChrome
%       token, so the window is light on a light desktop and dark on a dark one.
%     - Update Fit was a hard-coded [0 0.65 1]. It is the primary action in this
%       window, which is what the accent token means, and the token carries a
%       contrast floor its literal did not.
    fig = figure( ...
        'Tag',              'Simu', ...
        'Name',             name, ...
        'Units',            'pixels', ...
        'Position',         [644 342 853 871], ...
        'Color',            qmrlabUIColor('viewerChrome'), ...
        'MenuBar',          'none', ...
        'ToolBar',          'figure', ...
        'NumberTitle',      'off', ...
        'IntegerHandle',    'off', ...
        'Resize',           'on', ...
        'HandleVisibility', 'callback', ...
        'Visible',          'off');
    movegui(fig, 'onscreen');

    handles        = struct();
    handles.Simu   = fig;   % other Sim windows and printdlg reach the figure by this
    handles.output = fig;

    handles.uipanel14 = uipanel( ...
        'Parent',     fig, ...
        'Tag',        'uipanel14', ...
        'Title',      'Parameters', ...
        'Units',      'normalized', ...
        'Position',   [0.0257913 0.621125 0.953107 0.378875], ...
        'FontSize',   10, ...
        'BorderType', 'none');

    % ColumnName and ColumnFormat are load-bearing, not decoration:
    % UpdatePlot_Callback writes the fit back into columns 3-5 BY INDEX.
    handles.ParamTable = uitable( ...
        'Parent',         handles.uipanel14, ...
        'Tag',            'ParamTable', ...
        'Units',          'normalized', ...
        'Position',       [0.356894 0.0861068 0.584121 0.856967], ...
        'FontSize',       10, ...
        'ColumnName',     {'Name', 'Input', 'Fitted', 'Pct. error', 'Pct. CRLB'}, ...
        'RowName',        {}, ...   % the .fig stored it EMPTY; omitting it numbers the rows
        'ColumnFormat',   {'char', 'numeric', 'numeric', 'numeric', []}, ...
        'ColumnEditable', [false true false false false], ...
        'ColumnWidth',    {70, 95, 95, 95, 95});

    handles.OptionsPanel = uipanel( ...
        'Parent',   handles.uipanel14, ...
        'Tag',      'OptionsPanel', ...
        'Title',    'Options', ...
        'Units',    'normalized', ...
        'Position', [0.0321081 0.0738058 0.311202 0.877469]);

    handles.uipanel_curve = uipanel( ...
        'Parent',     fig, ...
        'Tag',        'uipanel_curve', ...
        'Title',      'Fitted Curve', ...
        'Units',      'normalized', ...
        'Position',   [0.0257913 -0.00114811 0.953107 0.615385], ...
        'FontSize',   10, ...
        'BorderType', 'none');

    handles.SimCurveAxe = axes( ...
        'Parent',   handles.uipanel_curve, ...
        'Tag',      'SimCurveAxe', ...
        'Units',    'normalized', ...
        'Position', [0.0765432 0.118375 0.881481 0.809187], ...
        'FontSize', 10, ...
        'Color',    [1 1 1]);

    handles.UpdatePlot = uicontrol( ...
        'Parent',          handles.uipanel_curve, ...
        'Style',           'pushbutton', ...
        'Tag',             'UpdatePlot', ...
        'String',          'Update Fit', ...
        'Units',           'normalized', ...
        'Position',        [0.746584 0.951737 0.217391 0.0521236], ...
        'FontSize',        10, ...
        'FontWeight',      'bold', ...
        'BackgroundColor', qmrlabUIColor('accent'), ...
        'ForegroundColor', qmrlabUIColor('onTheAccent'), ...
        'Callback',        @(src, ~) UpdatePlot_Callback(src, [], guidata(src)));

    guidata(fig, handles);
    fig.Visible = 'on';
end

% ----------------------------------------------------------------------------
function showModel(fig, Model)
%SHOWMODEL  Point an already-built window at a model. Runs on EVERY open.
%
%   The GUIDE version did this once, behind an `~isfield(handles,'opened')` guard
%   that also held the handles.Model assignment -- so opening the window on one
%   model and then on another left it simulating the FIRST one, silently, because
%   MethodMenu does not tear these windows down when the method changes. This one
%   re-points, which is what a user asking for a model's simulation means.
    busy = findall(groot, 'Type', 'figure', 'Name', 'qMRLab');
    set(busy, 'pointer', 'watch'); drawnow;
    restore = onCleanup(@() set(busy(isgraphics(busy)), 'pointer', 'arrow')); %#ok<NASGU>

    setappdata(0, 'Model', Model);
    handles       = guidata(fig);
    handles.Model = Model;

    % Rebuilt from THIS model, so re-opening on another does not leave the
    % previous model's controls stacked in the panel.
    delete(allchild(handles.OptionsPanel));
    if isprop(Model, 'Sim_Single_Voxel_Curve_buttons')
        opts = Model.Sim_Single_Voxel_Curve_buttons;
    else
        opts = {'SNR', 50};   % every model gets an SNR: :138 reads it back by name
    end
    handles.options = GenerateButtonsWithPanels(opts, handles.OptionsPanel);

    % Style is safe here -- these are legacy uicontrols in a legacy figure, not
    % the native components where get(h,'Style') throws or returns a style table.
    ff = fieldnames(handles.options);
    for ii = 1:numel(ff)
        h = handles.options.(ff{ii});
        if isgraphics(h) && strcmp(get(h, 'Style'), 'togglebutton')
            % guidata(src) rather than a captured copy: guidata hands back a COPY
            % of the struct, so a callback built with today's handles would keep
            % reading today's model forever.
            set(h, 'Callback', @(src, ~) ModelSimOptions_Callback(guidata(src)));
        end
    end

    Nparam = numel(Model.xnames);
    FitOptTable = cell(Nparam, 2);
    FitOptTable(:,1) = Model.xnames(:);
    if isprop(Model, 'st') && ~isempty(Model.st)
        FitOptTable(:,2) = num2cell(Model.st(:));
    elseif isprop(Model, 'lb') && ~isempty(Model.lb) && ...
           isprop(Model, 'ub') && ~isempty(Model.ub)
        FitOptTable(:,2) = num2cell(mean([Model.lb(:), Model.ub(:)], 2));
    end
    set(handles.ParamTable, 'Data', FitOptTable);

    handles.opened = true;
    guidata(fig, handles);
    drawnow;
end

% ----------------------------------------------------------------------------
% --- Executes on button press in UpdatePlot.
function UpdatePlot_Callback(hObject, eventdata, handles) %#ok<INUSL>
Model_new = getappdata(0,'Model');
if ~isempty(Model_new) && strcmp(class(Model_new),class(handles.Model))
    handles.Model = Model_new;
end

set(findall(groot,'Type','figure','Name','Single Voxel Curve'),'pointer', 'watch'); drawnow;
pointer_restore = onCleanup(@() set(findall(groot,'Type','figure','Name','Single Voxel Curve'),'pointer', 'arrow')); %#ok<NASGU>

if isgraphics(handles.SimCurveAxe)
    axes(handles.SimCurveAxe)
end

xtable = get(handles.ParamTable,'Data');
x=cell2mat(xtable(~cellfun(@isempty,xtable(:,2)),2))';

FitResults = Sim_Single_Voxel_Curve(handles.Model,x,button_handle2opts(handles.options));
hold off;

% put results in table
ff = fieldnames(FitResults);
for ii=1:length(ff)
    index = strcmp(xtable(:,1),ff{ii});
    if find(index)
        xtable{index,3} = FitResults.(ff{ii})(1);
        xtable{index,4} = round((FitResults.(ff{ii})(1) - xtable{index,2})/xtable{index,2}*100);
    else
        xtable{end+1,1} = ff{ii}; %#ok<AGROW>
        xtable{end,3} = FitResults.(ff{ii})(1);
    end
end

% CRLB
SNR = str2double(get(handles.options.SNR,'String'));
[~,~,~,F] = SimCRLB(handles.Model,handles.Model.Prot.(handles.Model.MRIinputs{1}).Mat,x,1/SNR);

for ii=1:sum(~handles.Model.fx)
    ll=find(~handles.Model.fx);
    xtable{ll(ii),5}=F(ii)*100;
end
set(handles.ParamTable,'Data',xtable);
drawnow;
end

% --- Executes on button press in Options panel.
function ModelSimOptions_Callback(handles)
xtable = get(handles.ParamTable,'Data');
x=cell2mat(xtable(~cellfun(@isempty,xtable(:,2)),2))';
xnew = SimOpt(handles.Model,x,button_handle2opts(handles.options));
if ~isempty(xnew) % update the ParamTable in the GUI
    Nparam = length(handles.Model.xnames);
    xtable(1:Nparam,2) = mat2cell(xnew',ones(Nparam,1));
    set(handles.ParamTable,'Data',xtable);
end
end
