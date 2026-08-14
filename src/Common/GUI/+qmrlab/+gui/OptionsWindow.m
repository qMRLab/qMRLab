classdef OptionsWindow < matlab.apps.AppBase
%   qMRLab per-model options window.
%
%   Unwrapped from src/Common/GUI/Custom_OptionsGUI.mlapp. Renders each model's
%   `buttons` declaration at runtime; see src/Common/tools/GenerateButtonsWithPanels.m.
%
%   See docs/adr/0001-gui-migration.md.

    % Properties that correspond to app components
    properties (Access = public)
        OptionsGUI          matlab.ui.Figure
        uipanel29           matlab.ui.container.Panel
        OptionsPanel        matlab.ui.container.Panel
        OptionsGrid         matlab.ui.container.GridLayout
        ShellGrid           matlab.ui.container.GridLayout
        RightGrid           matlab.ui.container.GridLayout
        OptionsHost         matlab.ui.container.Panel
        ParametersFileName  matlab.ui.control.Label
        Save                matlab.ui.control.Button
        Load                matlab.ui.control.Button
        textCurrent         matlab.ui.control.Label
        Default             matlab.ui.control.Button
        Helpbutton          matlab.ui.control.Button
        ProtEditPanel       matlab.ui.container.Panel
        ProtEditGrid        matlab.ui.container.GridLayout
        FitOptEditPanel     matlab.ui.container.Panel
        FitOptTable         matlab.ui.control.Table
    end

    properties (Constant, Access = private)
        % The protocol table's height. Enough for a header plus ~4 rows, which
        % covers every shipped model's default protocol; longer ones scroll inside
        % the table rather than making the panel grow without bound.
        TABLEHEIGHT = 130
    end

    properties (Access = private)
        Model               % Store the model object
        caller              % Handle to caller GUI
        OptionsPanel_handle % Handle to dynamic options components
        ProtPanels          % Structure to store protocol panels
        root                % Root directory
        opened = false      % Track if opened
    end
    methods (Access = private)
        function applyTheme(app)
            % Registered here rather than at construction so a reopened window
            % re-registers: an Options window left open across a mode change used
            % to keep the tokens it was built with, because nothing told it.
            setappdata(app.OptionsGUI, 'qmrlabThemeRepaint', @() app.applyTheme());
            % Stage D2. The same ~150 lines MainApp carried, duplicated here --
            % including its own copy of the OS dark-mode probe, so the two windows
            % could in principle have disagreed about the appearance.
            %
            % One line now. The window themes itself, its explicit colours are gone,
            % and qmrlab.gui.Theme owns the single OS query.
            qmrlab.gui.Theme.adopt(app.OptionsGUI);
            qmrlab.gui.Theme.repaint(app.OptionsGUI);
        end

        function CreateProt_Callback(app, hObject, eventdata, MRIinput)
            app.Model = getappdata(0,'Model');
            Fmt = app.Model.Prot.(MRIinput).Format; if ischar(Fmt), Fmt = {Fmt}; end
            answer = inputdlg(Fmt,'Enter values, vectors or Matlab expressions',[1 100]);
            if isempty(answer), return; end
            Prot = cellfun(@str2num,answer,'uni',0);
            Prot = cellfun(@(x) x(:),Prot,'uni',0);
            Nlines = max(cell2mat(cellfun(@length,Prot,'uni',0)));
            app.Model.Prot.(MRIinput).Mat = NaN(Nlines,length(Fmt));
            for ic = 1:length(Fmt)
                if length(Prot{ic})>1
                    Lmax = length(Prot{ic}); % if vector, fill as many as possible
                else
                    Lmax = Nlines; % if scalar, all lines get this value
                end
                if isempty(Prot{ic}), Prot{ic} = NaN; end
                app.Model.Prot.(MRIinput).Mat(1:Lmax,ic) = Prot{ic};
            end
            Prot = app.Model.Prot.(MRIinput).Mat;
            set(app.ProtPanels.(MRIinput).table,'Data',Prot)
            UpdateProt(app, MRIinput,Prot)
        end

        function DefaultProt_Callback(app, hObject, eventdata)
            app.Model = getappdata(0,'Model');
            modelfun = str2func(class(app.Model));
            defaultModel = modelfun();
            app.Model.Prot = defaultModel.Prot;
            setappdata(0,'Model',app.Model);
            set(app.ProtFileName,'String','Protocol Filename');
            OptionsGUI_OpeningFcn(hObject, eventdata, app.Model, app.caller)
        end

        function GenSeq_Callback(app, hObject, eventdata, field)
            % GENERATE SEQUENCE

            Prot = GetProt(handles);
            ti = get(app.TiBox,'String');
            td = get(app.TdBox,'String');
            [Prot.ti,Prot.td] = SIRFSE_GetSeq( eval(ti), eval(td) );
            SetProt(Prot);
        end

        function LoadProt_Callback(app, hObject, eventdata, MRIinput)
            FileFormat = '*.mat;*.xls;*.xlsx;*.txt';
            if strcmp(MRIinput,'DiffusionData')
                FileFormat = ['*.bvec;*.scheme;' FileFormat];
            end
            [FileName,PathName] = uigetfile({FileFormat},'Load Protocol Matrix');
            if PathName == 0, return; end
            fullfilepath = [PathName, FileName];
            Prot = ProtLoad(fullfilepath);
            if Prot == 0, return; end
            if ~isnumeric(Prot), errordlg('Invalid protocol file'); return; end
            set(app.ProtPanels.(MRIinput).table,'Data',Prot)
            app.Model = getappdata(0,'Model');
            app.Model.Prot.(MRIinput).Mat = Prot;
            UpdateProt(app, MRIinput,Prot)
        end

        function renderOptions(app)
            % Rebuild the option widgets from the model's current `buttons` cell.
            %
            % This has to run again after every option change, not just at open:
            % models express UI intent by rewriting their own `buttons` (the '##'
            % disabled and '**' invisible prefixes, driven by AbstractModel's
            % linkGUIState). Without a re-render those changes never reach the
            % screen -- which is what left qsm_sb's and mt_sat's dependent controls
            % inert.
            %
            % Scoped deliberately to OptionsPanel. The original re-entered the whole
            % opening function, which also re-created the protocol panels without
            % ever deleting them, so handles grew without bound for the life of the
            % window.

                if ~isempty(app.Model.buttons)

                    % Stage E3. Options are rendered from parseButtons descriptors
                    % onto a scrollable grid of native components.
                    %
                    % The renderer applies each option's CURRENT value from
                    % Model.options itself, so the "now put the values back" loop
                    % that used to follow is gone. That loop existed because the
                    % generator could only seed from the DECLARED default, and it
                    % re-derived each value with a different switch from the one
                    % that read it back -- two places to keep in step.
                    app.OptionsPanel_handle = qmrlab.gui.OptionsRenderer.render( ...
                        app.Model, app.OptionsHost, ...
                        @(src,event) ModelOptions_Callback(app, app));

                    % Noted some concerns @ issue #253
                    SetOpt(app, app);
                end

        end

        function ModelOptions_Callback(app, handles)
            app.Model = SetOpt(app, handles);
            renderOptions(app);
        end

        function OptionsGUI_CloseRequestFcn(app, hObject, eventdata, handles)
            if isequal(get(hObject, 'waitstatus'), 'waiting')
                % The GUI is still in UIWAIT, us UIRESUME
                uiresume(hObject);
            end
        end

        function PointAdd_Callback(app, hObject, eventdata, field)
            % ADD POINT

            selected = app.ProtPanels.(field).CellSelect;
            oldDat = get(app.ProtPanels.(field).table,'Data');
            nRows = size(oldDat,1);
            data = nan(nRows+1,size(oldDat,2));
            if (numel(selected)==0)
                data(1:nRows,:) = oldDat;
            else
                % Fix the array bounds issue by checking selection validity
                if selected(1) <= nRows
                    data(1:selected(1),:) = oldDat(1:selected(1),:);
                    data(selected(1)+2:end,:) = oldDat(selected(1)+1:end,:);
                else
                    % If selection is out of bounds, just append at the end
                    data(1:nRows,:) = oldDat;
                end
            end
            set(app.ProtPanels.(field).table,'Data',data);
            UpdateProt(app, field,data)
        end

        function PointDown_Callback(app, hObject, eventdata, field)
            % MOVE POINT DOWN

            selected = app.ProtPanels.(field).CellSelect;
            data = get(app.ProtPanels.(field).table,'Data');
            oldDat = data;
            if (numel(selected)==0)
                return;
            else
                data(selected(1)+1,:) = oldDat(selected(1),:);
                data(selected(1),:) = oldDat(selected(1)+1,:);
            end
            set(app.ProtPanels.(field).table,'Data',data);
            UpdateProt(app, field,data)
        end

        function PointHelp_Callback(app, hObject, eventdata, Tip)
            % SHOW PROT HELP

            if ~isempty(Tip.link)
                web(Tip.link)
            end
            helpdlg(Tip.tip)
        end

        function PointRem_Callback(app, hObject, eventdata, field)
            % REMOVE POINT

            selected = app.ProtPanels.(field).CellSelect;
            data = get(app.ProtPanels.(field).table,'Data');
            nRows = size(data,1);
            if (numel(selected)==0)
                data = data(1:nRows-1,:);
            else
                data (selected(:,1), :) = [];
            end
            set(app.ProtPanels.(field).table,'Data',data);
            UpdateProt(app, field,data)
        end

        function PointUp_Callback(app, hObject, eventdata, field)
            % MOVE POINT UP

            selected = app.ProtPanels.(field).CellSelect;
            data = get(app.ProtPanels.(field).table,'Data');
            oldDat = data;
            if (numel(selected)==0)
                return;
            else
                data(selected(1)-1,:) = oldDat(selected(1),:);
                data(selected(1),:) = oldDat(selected(1)-1,:);
            end
            set(app.ProtPanels.(field).table,'Data',data);
            UpdateProt(app, field,data)
        end

        function SeqTable_CellSelectionCallback(app, hObject, eventdata, field)
            % CELL SELECT

            app.ProtPanels.(field).CellSelect = eventdata.Indices;
        end

        function Model = SetOpt(app, handles)
            % GETFITOPT Get Fit Option from table

            % READ FITTING TABLE
            fittingtable = get(app.FitOptTable,'Data'); % Get options
            Model = getappdata(0,'Model');
            Model.xnames = fittingtable(:,1)';

            % Manage R1map and R1r in qmt_SPGR
            indR1map = cellfun(@(x) strcmp(x,'R1MAP'), fittingtable);
            indR1map(:,1)=false;
            if sum(indR1map(:))
                fittingtable{indR1map} = Model.st(strcmp(Model.xnames,'R1f'));
            end
            indR1f = cellfun(@(x) strcmp(x,'R1f'), fittingtable);
            indR1f(:,1)=false;
            if sum(indR1f(:))
                fittingtable{indR1f} = Model.st(strcmp(Model.xnames,'R1r'));
            end
            indT2f = cellfun(@(x) strcmp(x,'(R1f*T2f)/R1f'), fittingtable);
            indT2f(:,1)=false;
            if sum(indT2f(:))
                fittingtable{indT2f} = Model.st(strcmp(Model.xnames,'T2f'));
            end

            if ~isprop(Model, 'voxelwise') || (isprop(Model, 'voxelwise') && Model.voxelwise ~= 0)
                if size(fittingtable,2)>1, Model.fx = cell2mat(fittingtable(:,2)'); end
                if size(fittingtable,2)>2
                    if ~any(cellfun('isempty',fittingtable(:,3)))
                        Model.st = cell2mat(fittingtable(:,3)');
                        if isprop(Model,'lb') && isprop(Model,'ub')
                            % check that starting point > lb and < ub
                            Model.st = max([Model.st; Model.lb],[],1);
                            Model.st = min([Model.st; Model.ub],[],1);
                            fittingtable(:,3) = mat2cell(Model.st(:),ones(length(Model.st),1));
                        end
                    end
                    if isprop(Model,'lb') && isprop(Model,'ub')
                        Model.lb = cell2mat(fittingtable(:,4)');
                        Model.ub = cell2mat(fittingtable(:,5)');
                    end
                    if isfield(Model.options,'fittingconstraints_UseR1maptoconstrainR1f') && Model.options.fittingconstraints_UseR1maptoconstrainR1f
                        fittingtable{strcmp(fittingtable(:,1),'R1f'),3}='R1MAP';
                    end
                    if isfield(Model.options,'fittingconstraints_FixR1rR1f')  && Model.options.fittingconstraints_FixR1rR1f
                        fittingtable{strcmp(fittingtable(:,1),'R1r'),3}='R1f';
                    end
                    if isfield(Model.options,'fittingconstraints_FixR1fT2f')  && Model.options.fittingconstraints_FixR1fT2f && (~isfield(Model.options,'Model') || ~any(strcmp(Model.options.Model,{'SledPikeRP', 'SledPikeCW'})))
                        fittingtable{strcmp(fittingtable(:,1),'T2f'),3}='(R1f*T2f)/R1f';
                    end
                    set(app.FitOptTable,'Data',fittingtable);
                end
            end


            % READ BUTTONS
            Model.options = button_handle2opts(app.OptionsPanel_handle);

            if ismethod(Model,'UpdateFields')
                Model = Model.UpdateFields();
            end

            % SANITY CHECK
            Data = getappdata(0, 'Data');
            if ~isempty(Data) && isfield(Data,class(Model))
                % char(): [] when valid, and uilabel.Text rejects []. See BrowserSet.
                ErrMsg = char(Model.sanityCheck(Data.(class(Model))));
                % Text/Tooltip, not String/TooltipString: the target is the uilabel
                % MethodBrowser creates, not the GUIDE uicontrol these lines were
                % written for. This went unnoticed because the label carried no Tag,
                % so findobj returned empty and set() on an empty handle is a silent
                % no-op -- the data-consistency warning has never once been shown.
                % Tagging the label (MethodBrowser.m) is what made this reachable.
                hWarnBut = findobj('Tag',['WarnBut_DataConsistency_' class(Model)]);
                if ~isempty(hWarnBut)
                    set(hWarnBut, 'Text', ErrMsg, 'Tooltip', ErrMsg, ...
                                  'Visible', matlab.lang.OnOffSwitchState(~isempty(ErrMsg)));
                end
            end

            % SAVE
            setappdata(0,'Model',Model);
        end

        function UpdateProt(app, MRIinput, Prot)
            if ~isnumeric(Prot)
                h_table = Prot.Source;
                Prot = Prot.Source.Data;
            else
                h_table = app.ProtPanels.(MRIinput).table;
            end

            % Color problematic lines in red
            if ~isempty(find(isnan(Prot), 1))
                LinesColor = ones(size(Prot,1),3);
                LinesColor(2:2:end,:) = LinesColor(2:2:end,:)*0.9400;
                LinesColor(max(isnan(Prot),[],2),:) = repmat([.7 .5 .5],[sum(max(isnan(Prot),[],2)),1]);
                set(h_table,'BackgroundColor',LinesColor);
                return;
            end

            % if ok, load Prot into Model
            Model = getappdata(0,'Model');
            if isnumeric(Prot)
                Model.Prot.(MRIinput).Mat = Prot;
            else
                Model.Prot.(MRIinput).Mat = Prot.Source.Data;
            end
            if ismethod(Model,'UpdateFields')
                Model = Model.UpdateFields();
            end
            setappdata(0,'Model',Model);
        end

        % Update components that require runtime configuration
        function addRuntimeConfigurations(app)
            % Load data for component configuration
            componentData = load('Custom_OptionsGUI.mat');
            
            % No BackgroundColor: a uitable stripes itself from the theme, and the
            % two-row [base; stripe] the app used to compute was just the light
            % palette restated. Stating it is what stopped the table going dark.
            app.FitOptTable.ColumnFormat = {'char' 'logical' 'numeric' 'numeric' 'numeric'};
            app.FitOptTable.Data = componentData.FitOptTable.Data;
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function OptionsGUI_OpeningFcn(app, varargin)
            % Add runtime required configuration - Added by Migration Tool
            addRuntimeConfigurations(app);

            % Ensure that the app appears on screen when run
            movegui(app.OptionsGUI, 'onscreen');

            applyTheme(app);
            qmrlab.gui.Theme.attachMenu(app.OptionsGUI);

            % This function is called each time the Options Panel is opened.
            %
            % OptionsPanel is a non-modal window with the <uipanel29> ID in handles
            % Note that what word "PANEL" refers to may be ambigious.
            %
            % app.OptionsPanel is to access non-modal uipanel29 window. In this
            % window, there are 3 sub-windows for Protocol, FitOpt and Options located
            % on the left half, right half upper and right half lower, respectively.
            %
            % i.e. uipanel29 is the main options panel. It has 3 children (sub-panels):
            %
            % OptionsPanel (right half lower, by default)
            % ProtEditPanel (left half, by default)
            % FitOptEditPanel   (right half upper, by default)
            %
            % Whereas in the buttons context, a PANEL refers to a container object that
            % scopes multiple UIObjects (i.e. button groups).
            % See GenerateButtonsWithPanels.m for a beter understanding.
            %


            % varargin contians command line arguments to this UI.
            % i)  Should be containg the object for the first model on the dropdown list
            % ii) Should be contaning UIFigure object belonging to the main qMRLab window

            % Check if command line arguments contain wait command as the last one.
            % TRAVIS env triggers this. If this is the case, Options Panel
            % execution will be blocked. See if wait statement at the end of this fun.

            % INITIALIZE OPTIONSGUI PANEL
            % =======================================================================

            if any(strcmp(varargin,'wait'))
                wait=true;
                varargin(strcmp(varargin,'wait'))=[];
            else
                wait=false;
            end

            % GET/SET MODEL
            % =======================================================================

            % Retrieve model parameters from the shared data scope of UIs, if varargin
            % does not contain any command line arguments.

            % If it contains, the first argument must be a Model as assigned by mainApp
            % (inversion_recovery as for Aug 2018).


            % Store model in app property
            if ~isempty(varargin)
                app.Model = varargin{1};
            else
                app.Model = getappdata(0,'Model');
            end

            % Assign this model to the shared data scope of UIs.
            setappdata(0,'Model',app.Model);


            % Assign OptionsGUI title with the Model name
            app.uipanel29.Title = [strrep(app.Model.ModelName, '_', ' ') ' options'];


            % Get root dir for where this script is located

            app.root = fileparts(which('qMRLab.m'));

            % Handle to caller GUI

            app.caller = [];

            % If called from GUI, set position to dock left

            if (length(varargin)>1 && ~isempty(varargin{2}) && ~app.opened)

                app.caller = varargin{2};

                CurrentPos = app.OptionsGUI.Position;

                CallerPos = get(app.caller, 'Position');

                NewPos = [CallerPos(1)+CallerPos(3), CallerPos(2)+CallerPos(4)-CurrentPos(4), CurrentPos(3), CurrentPos(4)];

                app.OptionsGUI.Position = NewPos;
            end

            app.opened = 1;


            % POPULATE FITOPTEDIT SUB-PANEL
            % ======================================================================

            % Note that this panel and equation member function are codependent.

            % Get the length of the fitted parameters

            Nparam = length(app.Model.xnames);

            % FitOptTable related conditional block

            if ~isprop(app.Model, 'voxelwise') || (isprop(app.Model, 'voxelwise') && app.Model.voxelwise ~= 0)

                FitOptTable(:,1) = app.Model.xnames(:);

                if isprop(app.Model,'fx') && ~isempty(app.Model.fx), FitOptTable(:,2) = mat2cell(logical(app.Model.fx(:)),ones(Nparam,1)); end

                if isprop(app.Model,'st') && ~isempty(app.Model.st)

                    FitOptTable(:,3) = mat2cell(app.Model.st(:),ones(Nparam,1));

                end

                if isprop(app.Model,'lb') && ~isempty(app.Model.lb) && isprop(app.Model,'ub') && ~isempty(app.Model.ub)

                    FitOptTable(:,4) = mat2cell(app.Model.lb(:),ones(Nparam,1));
                    FitOptTable(:,5) = mat2cell(app.Model.ub(:),ones(Nparam,1));

                end

                set(app.FitOptTable,'Data',FitOptTable)

                % Add TooltipString
                try

                    modelheader=iqmr_header.header_parse(which(app.Model.ModelName));
                    modelheader=modelheader.output';
                    set(app.FitOptTable,'TooltipString', sprintf('%-10s: %s\n',modelheader{:}));

                catch

                    warning('Problem with adding TooltipString');

                end
            end

            % MODEL PROPERTY ADAPTIVE DYNAMIC SUBPANELS
            % ======================================================================

            % Hide FittingOptions panel if equation is not a member funciton.
            % Give the space to the Options initially. If there is no options, then
            % remove that one too and leave Protocol only.

            % If there is no protocol neither then just close the whole thing :D

            % Denoising, noise level: No Protocol
            % B1 dam has nothing.
            % vfa_t1 has no options.


            % Named, not allchild(...) indexed by position: chld(2) and chld(3)
            % meant ProtEditPanel and FitOptEditPanel purely by creation order, so
            % adding any child to uipanel29 silently retargeted them -- and this
            % commit adds one.
            %
            % The original conditions are preserved exactly rather than tidied. Three
            % overlapping if-blocks, collapsed to their union:
            %     hide FitOpt  iff  ~hasEquation && (hasOptions || ~hasProt)
            %     hide Prot    iff  ~hasEquation && ~hasProt
            % which does mean a model with an equation but no protocol still shows an
            % empty Protocol panel. That looks wrong and is left alone: changing which
            % panels appear would make any screenshot difference impossible to
            % attribute to the layout change.
            hasEquation = ismember('equation', methods(app.Model));
            hasOptions  = ~isempty(fieldnames(app.Model.options));
            hasProt     = ~isempty(app.Model.Prot) && ~isempty(fieldnames(app.Model.Prot));

            if ~hasEquation && (hasOptions || ~hasProt)
                app.FitOptEditPanel.Visible = 'off';
                app.RightGrid.RowHeight{1} = 0;
            end
            if ~hasEquation && ~hasProt
                app.ProtEditPanel.Visible = 'off';
                app.ShellGrid.ColumnWidth{1} = 0;
            end

            % POPULATE OPTIONSPANEL
            % =======================================================================

            renderOptions(app);

            % POPULATE PROTOCOL PANEL
            % =======================================================================

            if ~isempty(app.Model.Prot)

                fields = fieldnames(app.Model.Prot); fields = fields(end:-1:1);

                N = length(fields);

                % Each protocol panel used to get .9/N of the height, which is fine
                % for one or two and hopeless for five: mp2rage has five, so a panel
                % came to ~139 px and the table inside it collapsed to ZERO height
                % once the buttons were given the room they need. The old code made
                % the opposite trade -- a roomy table and ~14 px unreadable buttons.
                %
                % Neither is a layout. Give every panel the height it actually needs
                % and let the column scroll when there are too many to fit, which is
                % the same answer as the Datasets panel and the viewer strip.
                app.ProtEditGrid = uigridlayout(app.ProtEditPanel, [N+1 1]);
                % 'fit': each panel is exactly as tall as its table plus its buttons,
                % so a two-row protocol does not reserve the same space as a ten-row
                % one. The column scrolls when the total exceeds the window.
                app.ProtEditGrid.RowHeight   = [repmat({'fit'}, 1, N), {'fit'}];
                app.ProtEditGrid.ColumnWidth = {'1x'};
                app.ProtEditGrid.Padding     = [6 6 6 6];
                app.ProtEditGrid.RowSpacing  = 6;
                app.ProtEditGrid.Scrollable  = 'on';

                for ii = 1:N

                    app.ProtPanels.(fields{ii}).CellSelect = [];

                    % Create PANEL
                    % Panels function as a namespace for protocols.
                    % Unlike options panel, here they are REQUIRED.

                    app.ProtPanels.(fields{ii}).panel = uipanel(app.ProtEditGrid,'Title',fields{ii});
                    app.ProtPanels.(fields{ii}).panel.Layout.Row = ii;
                    app.ProtPanels.(fields{ii}).panel.Layout.Column = 1;

                    % Stage E3. The panel's interior is a grid: table on top, the
                    % edit buttons in a fixed-height strip beneath.
                    %
                    % The buttons used to be normalized rectangles 0.02*N tall inside
                    % a panel 0.9/N tall -- the N cancels, so they came out ~14 px at
                    % EVERY protocol count, too short to render their own labels. In
                    % the qsm_sb capture "Add", "Move up" and "Load" are visibly
                    % clipped and run into each other. A 'fit' row is as tall as the
                    % button needs, at any N and any text size.
                    %
                    % The table's own 1-0.08*N height had the same shape of bug from
                    % the other end: it goes NEGATIVE at N >= 13. No shipped model has
                    % that many protocol fields, so it was latent rather than visible.
                    pg = uigridlayout(app.ProtPanels.(fields{ii}).panel, [2 1]);
                    % A fixed table height, not '1x'. With 'fit' rows above, '1x' has
                    % nothing to divide and the table collapsed to zero -- which is
                    % exactly what mp2rage's five panels did. The table scrolls
                    % internally past this many rows.
                    pg.RowHeight   = {qmrlab.gui.OptionsWindow.TABLEHEIGHT, 'fit'};
                    pg.ColumnWidth = {'1x'};
                    pg.Padding     = [6 6 6 6];
                    pg.RowSpacing  = 4;
                    app.ProtPanels.(fields{ii}).grid = pg;

                    app.ProtPanels.(fields{ii}).table = uitable(pg,'Data',app.Model.Prot.(fields{ii}).Mat);
                    app.ProtPanels.(fields{ii}).table.Layout.Row = 1;
                    app.ProtPanels.(fields{ii}).table.Layout.Column = 1;

                    % TODO: Condition to be improved.
                    if isprop(app.Model,'tabletip')

                        tbl_cur = app.Model.tabletip.table_name;
                        tip_cur = {app.Model.tabletip.tip};

                        if ismember(fields{ii},tbl_cur)

                            [~,tbidx] = ismember(fields{ii},tbl_cur);
                            set(app.ProtPanels.(fields{ii}).table,'Tooltip',char(tip_cur{tbidx}));

                        end

                    end


                    % add Callbacks

                    set(app.ProtPanels.(fields{ii}).table,'CellEditCallback', @(hObject,Prot) UpdateProt(app, fields{ii},Prot));
                    set(app.ProtPanels.(fields{ii}).table,'CellSelectionCallback', @(hObject, eventdata) SeqTable_CellSelectionCallback(app, hObject, eventdata, fields{ii}));
                    set(app.ProtPanels.(fields{ii}).table,'ColumnEditable', true);

                    if size(app.Model.Prot.(fields{ii}).Format,1) > 1
                        set(app.ProtPanels.(fields{ii}).table,'RowName', app.Model.Prot.(fields{ii}).Format);
                        set(app.ProtPanels.(fields{ii}).table,'ColumnName','');
                    else
                        % Native uibuttons, not uicontrol: a uicontrol cannot be a
                        % child of a uigridlayout at all (tCapabilities pins that).
                        bg = uigridlayout(pg, [4 2]);
                        bg.Layout.Row = 2;  bg.Layout.Column = 1;
                        bg.RowHeight     = {'fit','fit','fit','fit'};
                        bg.ColumnWidth   = {'1x','1x'};
                        bg.Padding       = [0 0 0 0];
                        bg.RowSpacing    = 3;
                        bg.ColumnSpacing = 4;

                        specs = { 'Add',       1, 1, @PointAdd_Callback; ...
                                  'Remove',    1, 2, @PointRem_Callback; ...
                                  'Move up',   2, 1, @PointUp_Callback; ...
                                  'Move down', 2, 2, @PointDown_Callback; ...
                                  'Load',      3, 1, @LoadProt_Callback; ...
                                  'Create',    3, 2, @CreateProt_Callback };
                        btns = gobjects(1, size(specs,1));
                        for bi = 1:size(specs,1)
                            cb = specs{bi,4};
                            btns(bi) = uibutton(bg, 'push', 'Text', specs{bi,1}, ...
                                'ButtonPushedFcn', @(hObject, eventdata) cb(app, hObject, eventdata, fields{ii}));
                            btns(bi).Layout.Row = specs{bi,2};
                            btns(bi).Layout.Column = specs{bi,3};
                        end
                        app.ProtPanels.(fields{ii}).buttons = btns;
                        app.ProtPanels.(fields{ii}).buttongrid = bg;

                        set(app.ProtPanels.(fields{ii}).table,'ColumnName',app.Model.Prot.(fields{ii}).Format);
                        if isprop(app.Model,'tabletip')

                            tbl_cur = app.Model.tabletip.table_name;
                            tip_cur = {app.Model.tabletip.tip};

                            if ismember(fields{ii},tbl_cur)

                                [~,tbidx] = ismember(fields{ii},tbl_cur);
                                Tip = struct();
                                Tip.tip = tip_cur{tbidx};
                                if isfield(app.Model.tabletip,'link')
                                    Tip.link = cell2mat(app.Model.tabletip.link);
                                else
                                    Tip.link = [];
                                end

                                app.ProtPanels.(fields{ii}).help = uibutton(bg, 'push', ...
                                    'Text','?','BackgroundColor',[0, 0.65, 1],'FontColor',[1 1 1], ...
                                    'ButtonPushedFcn',@(hObject, eventdata) PointHelp_Callback(app, hObject, eventdata, Tip, fields{ii}));
                                app.ProtPanels.(fields{ii}).help.Layout.Row = 4;
                                app.ProtPanels.(fields{ii}).help.Layout.Column = [1 2];
                            end

                        end
                    end

                    % Make buttons invisible on condition.
                    if isprop(app.Model,'ProtStyle')

                        prot_names  = app.Model.ProtStyle.prot_namespace;
                        styles = {app.Model.ProtStyle.style};
                        [~,prtidx] = ismember(fields{ii},prot_names);

                        % The buttons are native components in their own grid now, so
                        % hide the ones we built rather than walking panel.Children
                        % looking for uicontrols -- there are none left to find, and
                        % that loop would silently stop hiding anything.
                        if strcmp(styles(prtidx),'TableNoButton')
                            if isfield(app.ProtPanels.(fields{ii}), 'buttons')
                                set(app.ProtPanels.(fields{ii}).buttons, 'Visible', 'off');
                            end
                            % Visible='off' hides the buttons but LEAVES THEIR ROW --
                            % measured on R2026b, a hidden component keeps its cell
                            % and everything below stays put. The panel then reserved
                            % ~86 px of blank space for controls nobody can see.
                            % Collapsing the row is what actually removes them.
                            if isfield(app.ProtPanels.(fields{ii}), 'grid') && ...
                                    isvalid(app.ProtPanels.(fields{ii}).grid)
                                app.ProtPanels.(fields{ii}).grid.RowHeight{2} = 0;
                            end
                            % Hide the STRIP, not just the buttons in it. A visible
                            % container collapsed to zero height is a defect by every
                            % sane definition -- geomAudit says so -- whereas an
                            % invisible one is simply absent, which is what
                            % TableNoButton means.
                            if isfield(app.ProtPanels.(fields{ii}), 'buttongrid') && ...
                                    isvalid(app.ProtPanels.(fields{ii}).buttongrid)
                                app.ProtPanels.(fields{ii}).buttongrid.Visible = 'off';
                            end
                            if isfield(app.ProtPanels.(fields{ii}), 'help') && ...
                                    ~isempty(app.ProtPanels.(fields{ii}).help)
                                app.ProtPanels.(fields{ii}).help.Visible = 'off';
                            end
                        end
                    end


                end
            end

            if ismethod(app.Model,'plotProt') && ~isempty(app.ProtEditGrid) && isvalid(app.ProtEditGrid)
                % Native button in the grid's last row. The old one was a uicontrol at
                % [.05 0 .9 .05], which overlapped the lowest protocol panel (that
                % panel starts at y = .05), and carried a STRING callback -- a
                % uicontrol-only feature with no equivalent on a native button.
                pb = uibutton(app.ProtEditGrid, 'push', 'Text', 'Plot Protocol', ...
                    'ButtonPushedFcn', @(~,~) plotProtocolCallback());
                pb.Layout.Row = numel(app.ProtEditGrid.RowHeight);
                pb.Layout.Column = 1;
            end

            % Wait if output
            if wait
                uiwait(app.OptionsGUI)
            end

            applyTheme(app);
        end

        % Button pushed function: Default
        function Default_Callback(app, event)
            % --- Executes on button press in Default.

            oldModel = getappdata(0,'Model');
            modelfun = str2func(class(oldModel));
            app.Model = modelfun();

            answer = questdlg('What do you want to set to default?','Reset protocol?','Reset options','Reset options AND protocol','Reset protocol','Reset options');
            if strfind(answer,'options')
                newModel = app.Model;
                newModel.Prot = oldModel.Prot;
            else
                newModel = oldModel;
            end
            if strfind(answer,'protocol')
                newModel.Prot = app.Model.Prot;
            end

            setappdata(0,'Model',newModel);
            set(app.ParametersFileName,'String','Parameters Filename');

        end

        % Cell edit callback: FitOptTable
        function FitOptTable_CellEditCallback(app, event)
            % FitOptTable CellEdit

            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>

            app.Model = SetOpt(app, handles);

        end

        % Button pushed function: Helpbutton
        function Helpbutton_Callback(app, event)
            % --- Executes on button press in Helpbutton.

            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>

            doc(class(getappdata(0,'Model')))
        end

        % Button pushed function: Load
        function Load_Callback(app, event)
            % --- Executes on button press in Load.

            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>

            [FileName,PathName] = uigetfile('*.mat');
            if PathName == 0, return; end
            app.Model = qMRloadObj(fullfile(PathName,FileName));
            oldModel = getappdata(0,'Model');
            if ~isa(app.Model,class(oldModel))
                errordlg(['Invalid protocol file. Select a ' class(oldModel) ' parameters file']);
                return;
            end
            setappdata(0,'Model',app.Model)
            set(app.ParametersFileName,'String',FileName);
            OptionsGUI_OpeningFcn(hObject, eventdata, handles, app.Model, app.caller)
        end

        % Button pushed function: Save
        function Save_Callback(app, event)
            % --- Executes on button press in Save.

            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>

            app.Model = getappdata(0,'Model');
            [file,path] = uiputfile([class(app.Model) '.qmrlab.mat'],'Save file name');
            if file
                app.Model.saveObj(fullfile(path,file))
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create OptionsGUI and hide until all components are created
            app.OptionsGUI = uifigure('Visible', 'off');
            colormap(app.OptionsGUI, 'parula');
            app.OptionsGUI.Position = [732 115 573 835];
            app.OptionsGUI.Name = 'OptionsGUI';
            app.OptionsGUI.HandleVisibility = 'on';
            app.OptionsGUI.Tag = 'OptionsGUI';

            % Create uipanel29
            app.uipanel29 = uipanel(app.OptionsGUI);
            app.uipanel29.Title = 'Options';
            app.uipanel29.Tag = 'uipanel29';
            app.uipanel29.FontWeight = 'bold';
            app.uipanel29.FontSize = 13.3333333333329;
            app.uipanel29.Position = [14 12 550 811];

            % Create FitOptEditPanel
            app.FitOptEditPanel = uipanel(app.uipanel29);
            app.FitOptEditPanel.TitlePosition = 'centertop';
            app.FitOptEditPanel.Title = 'Fitting';
            app.FitOptEditPanel.Tag = 'FitOptEditPanel';
            app.FitOptEditPanel.FontWeight = 'bold';
            app.FitOptEditPanel.FontSize = 13.3333333333329;
            app.FitOptEditPanel.Position = [280 592 256 196];

            % Create FitOptTable
            app.FitOptTable = uitable(app.FitOptEditPanel);
            app.FitOptTable.ColumnName = {'Var'; 'Fix'; 'Start'; 'Lower'; 'Upper'};
            app.FitOptTable.ColumnWidth = {47, 47, 47, 55, 55};
            app.FitOptTable.RowName = '';
            app.FitOptTable.ColumnEditable = [false true true true true];
            app.FitOptTable.CellEditCallback = createCallbackFcn(app, @FitOptTable_CellEditCallback, true);
            app.FitOptTable.Tag = 'FitOptTable';
            app.FitOptTable.FontSize = 10.6666666666667;
            app.FitOptTable.Position = [4 9 248 159];

            % Create ProtEditPanel
            app.ProtEditPanel = uipanel(app.uipanel29);
            app.ProtEditPanel.TitlePosition = 'centertop';
            app.ProtEditPanel.Title = 'Protocol';
            app.ProtEditPanel.Tag = 'ProtEditPanel';
            app.ProtEditPanel.FontWeight = 'bold';
            app.ProtEditPanel.FontSize = 13.3333333333329;
            app.ProtEditPanel.Position = [14 14 256 774];

            % Create OptionsPanel
            app.OptionsPanel = uipanel(app.uipanel29);
            app.OptionsPanel.TitlePosition = 'centertop';
            app.OptionsPanel.Title = 'Options';
            app.OptionsPanel.Tag = 'OptionsPanel';
            app.OptionsPanel.FontWeight = 'bold';
            app.OptionsPanel.FontSize = 13.3333333333329;
            app.OptionsPanel.Position = [283 14 256 567];

            % Create Helpbutton
            app.Helpbutton = uibutton(app.OptionsPanel, 'push');
            app.Helpbutton.ButtonPushedFcn = createCallbackFcn(app, @Helpbutton_Callback, true);
            app.Helpbutton.Tag = 'Helpbutton';
            qmrlab.gui.Theme.paint(app.Helpbutton, 'BackgroundColor', 'accent');
            qmrlab.gui.Theme.paint(app.Helpbutton, 'FontColor', 'onTheAccent');
            app.Helpbutton.FontSize = 13.3333333333329;
            app.Helpbutton.FontWeight = 'bold';
            app.Helpbutton.Position = [188 28 59.8653890364656 30.7609534856191];
            app.Helpbutton.Text = 'Help';

            % Create Default
            app.Default = uibutton(app.OptionsPanel, 'push');
            app.Default.ButtonPushedFcn = createCallbackFcn(app, @Default_Callback, true);
            app.Default.Tag = 'Default';
            app.Default.FontSize = 13.3333333333329;
            app.Default.Position = [127 29 60.5658161512079 27.5919866039906];
            app.Default.Text = 'Default';

            % Create textCurrent
            app.textCurrent = uilabel(app.OptionsPanel);
            app.textCurrent.Tag = 'textCurrent';
            app.textCurrent.VerticalAlignment = 'top';
            app.textCurrent.WordWrap = 'on';
            app.textCurrent.FontSize = 13.3333333333329;
            app.textCurrent.Position = [15 6 57.0031210834898 16.3043557205399];
            app.textCurrent.Text = 'Current:';

            % Create Load
            app.Load = uibutton(app.OptionsPanel, 'push');
            app.Load.ButtonPushedFcn = createCallbackFcn(app, @Load_Callback, true);
            app.Load.Tag = 'Load';
            app.Load.FontSize = 13.3333333333329;
            app.Load.Position = [69 29 60.5658161512079 27.5919866039906];
            app.Load.Text = 'Load';

            % Create Save
            app.Save = uibutton(app.OptionsPanel, 'push');
            app.Save.ButtonPushedFcn = createCallbackFcn(app, @Save_Callback, true);
            app.Save.Tag = 'Save';
            app.Save.FontSize = 13.3333333333329;
            app.Save.Position = [11 29 60.5658161512079 27.5919866039906];
            app.Save.Text = 'Save';

            % Create ParametersFileName
            app.ParametersFileName = uilabel(app.OptionsPanel);
            app.ParametersFileName.Tag = 'ParametersFileName';
            app.ParametersFileName.VerticalAlignment = 'top';
            app.ParametersFileName.WordWrap = 'on';
            app.ParametersFileName.FontSize = 13.3333333333329;
            app.ParametersFileName.Position = [78 5 160.321278047315 17.5585369298122];
            app.ParametersFileName.Text = 'Parameters filename';

            % --- The options column: generated options above, actions below.
            %
            % These used to be siblings in OptionsPanel -- groups stacking down from
            % y = 1 with no floor, buttons pinned near the bottom -- so they
            % collided. Measured on qsm_sb before this change, all four action
            % buttons sat underneath a generated panel. Separate rows make that
            % impossible instead of a question of how many options a model declares.
            app.OptionsGrid = uigridlayout(app.OptionsPanel, [3 1]);
            app.OptionsGrid.RowHeight   = {'1x', 'fit', 'fit'};
            app.OptionsGrid.ColumnWidth = {'1x'};
            app.OptionsGrid.Padding     = [4 4 4 4];
            app.OptionsGrid.RowSpacing  = 6;

            app.OptionsHost = uipanel(app.OptionsGrid, 'BorderType', 'none', 'Tag', 'OptionsHost');
            app.OptionsHost.Layout.Row = 1;  app.OptionsHost.Layout.Column = 1;

            acts = [app.Save, app.Load, app.Default, app.Helpbutton];
            actions = uigridlayout(app.OptionsGrid, [1 numel(acts)]);
            actions.Layout.Row = 2;  actions.Layout.Column = 1;
            actions.RowHeight     = {'fit'};
            actions.ColumnWidth   = repmat({'1x'}, 1, numel(acts));
            actions.Padding       = [0 0 0 0];
            actions.ColumnSpacing = 4;
            for ai = 1:numel(acts)
                acts(ai).Parent = actions;
                acts(ai).Layout.Row = 1;  acts(ai).Layout.Column = ai;
            end

            current = uigridlayout(app.OptionsGrid, [1 2]);
            current.Layout.Row = 3;  current.Layout.Column = 1;
            current.RowHeight     = {'fit'};
            current.ColumnWidth   = {'fit','1x'};
            current.Padding       = [0 0 0 0];
            current.ColumnSpacing = 4;
            app.textCurrent.Parent = current;
            app.textCurrent.Layout.Row = 1;  app.textCurrent.Layout.Column = 1;
            app.ParametersFileName.Parent = current;
            app.ParametersFileName.Layout.Row = 1;  app.ParametersFileName.Layout.Column = 2;

            % --- The shell, on a grid.
            %
            % Replaces the two runtime
            %     set(app.OptionsPanel,'Position',[0.5140 0.0158 0.4667 0.9735].*parent)
            % assignments -- the single mistake behind all 44 Stage A defects, and the
            % reason the "Options" title is clipped: 0.0158 + 0.9735 puts the panel's
            % top at 98.9% of uipanel29, so its centertop title rendered under
            % uipanel29's own border.
            %
            % This was attempted once before and reverted: making OptionsPanel taller
            % pushed the generated option stack off the bottom and over the action
            % buttons. That is fixed now -- the options scroll in their own row and
            % the buttons have theirs -- so widening the column is a row/column
            % COLLAPSE and nothing measures a parent and multiplies.
            app.ShellGrid = uigridlayout(app.uipanel29, [1 2]);
            app.ShellGrid.ColumnWidth   = {'1x', '1x'};
            app.ShellGrid.RowHeight     = {'1x'};
            app.ShellGrid.Padding       = [8 8 8 8];
            app.ShellGrid.ColumnSpacing = 8;

            app.ProtEditPanel.Parent = app.ShellGrid;
            app.ProtEditPanel.Layout.Row = 1;  app.ProtEditPanel.Layout.Column = 1;

            app.RightGrid = uigridlayout(app.ShellGrid, [2 1]);
            app.RightGrid.Layout.Row = 1;  app.RightGrid.Layout.Column = 2;
            app.RightGrid.RowHeight   = {196, '1x'};
            app.RightGrid.ColumnWidth = {'1x'};
            app.RightGrid.Padding     = [0 0 0 0];
            app.RightGrid.RowSpacing  = 8;

            app.FitOptEditPanel.Parent = app.RightGrid;
            app.FitOptEditPanel.Layout.Row = 1;  app.FitOptEditPanel.Layout.Column = 1;
            app.OptionsPanel.Parent = app.RightGrid;
            app.OptionsPanel.Layout.Row = 2;  app.OptionsPanel.Layout.Column = 1;

            % Show the figure after all components are created
            app.OptionsGUI.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = OptionsWindow(varargin)

            % Reuse a live instance rather than stacking windows. The generated
            % form focused whatever getRunningApp returned; this validates the
            % handle first so a torn-down instance cannot poison the next launch.
            runningApp = getRunningApp(app);
            if ~isempty(runningApp) && isvalid(runningApp) && isvalid(runningApp.OptionsGUI)
                figure(runningApp.OptionsGUI)
                app = runningApp;
                if nargout == 0
                    clear app
                end
                return
            end

            createComponents(app)
            registerApp(app, app.OptionsGUI)
            runStartupFcn(app, @(app)OptionsGUI_OpeningFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.OptionsGUI)
        end
    end
end

function plotProtocolCallback()
% Was a string callback on a uicontrol; native buttons take function handles only.
    Model = getappdata(0, 'Model');
    if isempty(Model); return; end
    figure('color', 'white');
    Model.plotProt;
end
