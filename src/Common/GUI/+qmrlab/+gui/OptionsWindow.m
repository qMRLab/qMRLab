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
        ParametersFileName  matlab.ui.control.Label
        Save                matlab.ui.control.Button
        Load                matlab.ui.control.Button
        textCurrent         matlab.ui.control.Label
        Default             matlab.ui.control.Button
        Helpbutton          matlab.ui.control.Button
        ProtEditPanel       matlab.ui.container.Panel
        FitOptEditPanel     matlab.ui.container.Panel
        FitOptTable         matlab.ui.control.Table
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
        function isDark = isSystemDarkMode(app)
            % Detect if system is in dark mode (Windows/Mac)
            if ispc
                % Windows registry check for dark mode
                try
                    [status, result] = system('reg query HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme');
                    if status == 0
                        isDark = contains(result, '0x0');
                    else
                        isDark = false;
                    end
                catch
                    isDark = false;
                end
            elseif ismac
                % macOS dark mode detection
                try
                    [status, result] = system('defaults read -g AppleInterfaceStyle');
                    isDark = status == 0 && contains(result, 'Dark');
                catch
                    isDark = false;
                end
            else
                % Linux or unknown - use default light mode
                isDark = false;
            end
        end

        function colors = getColorScheme(app)
            % Return appropriate color scheme based on system theme
            if app.isSystemDarkMode()
                % Dark mode colors
                colors.background = [0.15 0.15 0.15];
                colors.foreground = [0.9 0.9 0.9];
                colors.panelBg = [0.2 0.2 0.2];
                colors.panelFg = [0.95 0.95 0.95];
                colors.buttonBg = [0.3 0.3 0.3];
                colors.buttonFg = [0.95 0.95 0.95];
                colors.accent = [0.149 0.549 0.8667];
                colors.warning = [1 0.6 0.2];
                colors.success = [0.2 0.8 0.2];
                colors.tableBg = [0.25 0.25 0.25];
                colors.tableFg = [0.95 0.95 0.95];
                colors.tableStripe = [0.2 0.2 0.2];
            else
                % Light mode colors
                colors.background = [0.9412 0.9412 0.9412];
                colors.foreground = [0 0 0];
                colors.panelBg = [1 1 1];
                colors.panelFg = [0 0 0];
                colors.buttonBg = [0.902 0.902 0.902];
                colors.buttonFg = [0 0 0];
                colors.accent = [0.149 0.549 0.8667];
                colors.warning = [1 0.3294 0.3294];
                colors.success = [0.2 0.8 0.2];
                colors.tableBg = [1 1 1];
                colors.tableFg = [0 0 0];
                colors.tableStripe = [0.9412 0.9412 0.9412];
            end
        end

        function applyTheme(app)
            % Apply the current theme to all components
            colors = app.getColorScheme();

            % Apply to main figure and main panel
            app.OptionsGUI.Color = colors.background;
            app.uipanel29.BackgroundColor = colors.background;
            app.uipanel29.ForegroundColor = colors.foreground;

            % Apply to panels
            panelComponents = [app.FitOptEditPanel, app.ProtEditPanel, app.OptionsPanel];
            for i = 1:length(panelComponents)
                panelComponents(i).BackgroundColor = colors.panelBg;
                panelComponents(i).ForegroundColor = colors.panelFg;
            end

            % Apply to buttons
            buttonComponents = [app.Save, app.Load, app.Default, app.Helpbutton];
            for i = 1:length(buttonComponents)
                if ~isequal(buttonComponents(i).BackgroundColor, [0 0.650980392156863 1])
                    % Only change non-accent buttons
                    buttonComponents(i).BackgroundColor = colors.buttonBg;
                    buttonComponents(i).FontColor = colors.buttonFg;
                end
            end

            % Special handling for Help button (keep its blue color)
            app.Helpbutton.BackgroundColor = colors.accent;
            app.Helpbutton.FontColor = [1 1 1];

            % Apply to labels
            labelComponents = [app.textCurrent, app.ParametersFileName];
            for i = 1:length(labelComponents)
                labelComponents(i).FontColor = colors.foreground;
                if isequal(labelComponents(i).BackgroundColor, [0.902 0.902 0.902])
                    labelComponents(i).BackgroundColor = colors.background;
                end
            end

            % Apply to tables
            if isprop(app, 'FitOptTable') && isvalid(app.FitOptTable)
                app.FitOptTable.BackgroundColor = colors.tableBg;
                app.FitOptTable.ForegroundColor = colors.tableFg;
            end

            % Apply to dynamically created protocol tables
            if isprop(app, 'ProtPanels') && ~isempty(app.ProtPanels)
                fields = fieldnames(app.ProtPanels);
                for i = 1:length(fields)
                    if isfield(app.ProtPanels.(fields{i}), 'table') && isvalid(app.ProtPanels.(fields{i}).table)
                        app.ProtPanels.(fields{i}).table.BackgroundColor = colors.tableBg;
                        app.ProtPanels.(fields{i}).table.ForegroundColor = colors.tableFg;
                    end
                end
            end

            % Apply to dynamically created options components
            if isprop(app, 'OptionsPanel_handle') && ~isempty(app.OptionsPanel_handle)
                ff = fieldnames(app.OptionsPanel_handle);
                for ii = 1:length(ff)
                    comp = app.OptionsPanel_handle.(ff{ii});
                    if isvalid(comp)
                        try
                            switch get(comp, 'Type')
                                case 'uicontrol'
                                    style = get(comp, 'Style');
                                    switch style
                                        case {'pushbutton', 'togglebutton'}
                                            comp.BackgroundColor = colors.buttonBg;
                                            comp.ForegroundColor = colors.buttonFg;
                                        case {'checkbox', 'radiobutton', 'text', 'edit'}
                                            comp.BackgroundColor = colors.panelBg;
                                            comp.ForegroundColor = colors.foreground;
                                        case 'popupmenu'
                                            comp.BackgroundColor = colors.buttonBg;
                                            comp.ForegroundColor = colors.foreground;
                                    end
                                case 'uitable'
                                    comp.BackgroundColor = colors.tableBg;
                                    comp.ForegroundColor = colors.tableFg;
                                case 'uipanel'
                                    comp.BackgroundColor = colors.panelBg;
                                    comp.ForegroundColor = colors.panelFg;
                            end
                        catch
                            % Skip if property can't be set
                        end
                    end
                end
            end
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

        function ModelOptions_Callback(app, handles)
            app.Model = SetOpt(app, handles);
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
                ErrMsg = Model.sanityCheck(Data.(class(Model)));
                hWarnBut = findobj('Tag',['WarnBut_DataConsistency_' class(Model)]);
                if ~isempty(ErrMsg)
                    set(hWarnBut,'String',ErrMsg)
                    set(hWarnBut,'TooltipString',ErrMsg)
                    set(hWarnBut,'Visible','on')
                else
                    set(hWarnBut,'String','')
                    set(hWarnBut,'TooltipString','')
                    set(hWarnBut,'Visible','off')
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
            
            % Set component properties that require runtime configuration
            % Use theme-aware colors that will be overridden by applyTheme
            colors = app.getColorScheme();
            app.FitOptTable.BackgroundColor = [colors.tableBg; colors.tableStripe];
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


            chld = allchild(app.uipanel29);

            % FitOpt panel is not present

            if not(ismember('equation',methods(app.Model))) && not(isempty(fieldnames(app.Model.options))) && not(isempty(app.Model.Prot))

                set(chld(3),'Visible','off');
                % A uipanel inside a uifigure is PIXEL-united, so assigning this
                % GUIDE-era normalized rectangle raw collapsed the panel to
                % 0.5 x 0.016 px -- and every layout GenerateButtonsWithPanels
                % then derived from getpixelposition(parent) was garbage. That
                % single mistake accounted for all 44 defects found in the
                % Stage A triage. Scale against the parent instead.
                parentSize = getpixelposition(app.uipanel29);            % [x y w h]
                set(app.OptionsPanel, 'Position', ...
                    [0.5140 0.0158 0.4667 0.9735] .* parentSize([3 4 3 4]));

            end

            % FitOpt and protocol not present
            if not(ismember('equation',methods(app.Model))) && not(isempty(fieldnames(app.Model.options))) && (isempty(app.Model.Prot) || isempty(fieldnames(app.Model.Prot)))

                set(chld(3),'Visible','off');
                set(chld(2),'Visible','off');
                % A uipanel inside a uifigure is PIXEL-united, so assigning this
                % GUIDE-era normalized rectangle raw collapsed the panel to
                % 0.5 x 0.016 px -- and every layout GenerateButtonsWithPanels
                % then derived from getpixelposition(parent) was garbage. That
                % single mistake accounted for all 44 defects found in the
                % Stage A triage. Scale against the parent instead.
                parentSize = getpixelposition(app.uipanel29);            % [x y w h]
                set(app.OptionsPanel, 'Position', ...
                    [0.5140 0.0158 0.4667 0.9735] .* parentSize([3 4 3 4]));

            end




            % Nothing is present

            if (isempty(app.Model.Prot) || isempty(fieldnames(app.Model.Prot))) && not(ismember('equation',methods(app.Model)))

                set(chld(2),'Visible','off');
                set(chld(3),'Visible','off');

            end


            % POPULATE OPTIONSPANEL
            % =======================================================================

            if ~isempty(app.Model.buttons)

                % Delete UIObjects from the previous instance
                delete(findobj('Parent',app.OptionsPanel,'Type','uipanel'))

                % Generate UIObjects for options panel based on the "buttons" attribute
                % of the current model in the scope. Below function passes OptionsPanel
                % handle, and retrives the updated one with buttons (if present) on it.

                if isprop(app.Model,'tips')
                    app.OptionsPanel_handle = GenerateButtonsWithPanels(app.Model.buttons,app.OptionsPanel, app.Model.tips);
                else
                    app.OptionsPanel_handle = GenerateButtonsWithPanels(app.Model.buttons,app.OptionsPanel, []);

                end

                % Create CALLBACK for buttons and use value in Model.options (instead of the default one)

                ff = fieldnames(app.OptionsPanel_handle);

                for ii=1:length(ff)
                    if strcmp(get(app.OptionsPanel_handle.(ff{ii}),'type'),'uitable')
                        set(app.OptionsPanel_handle.(ff{ii}),'CellEditCallback',@(src,event) ModelOptions_Callback(app, app));
                        set(app.OptionsPanel_handle.(ff{ii}),'Data',app.Model.options.(ff{ii}));
                    else
                        set(app.OptionsPanel_handle.(ff{ii}),'Callback',@(src,event) ModelOptions_Callback(app, app));
                        switch get(app.OptionsPanel_handle.(ff{ii}),'Style')
                            case 'popupmenu'
                                val =  find(cell2mat(cellfun(@(x) strcmp(x,app.Model.options.(ff{ii})),get(app.OptionsPanel_handle.(ff{ii}),'String'),'UniformOutput',0)));
                                set(app.OptionsPanel_handle.(ff{ii}),'Value',val);
                            case 'checkbox'
                                set(app.OptionsPanel_handle.(ff{ii}),'Value',app.Model.options.(ff{ii}));
                            case 'edit'
                                set(app.OptionsPanel_handle.(ff{ii}),'String',app.Model.options.(ff{ii}));
                        end
                    end
                end
                % Noted some concerns @ issue #253
                SetOpt(app, app);
            end

            % POPULATE PROTOCOL PANEL
            % =======================================================================

            if ~isempty(app.Model.Prot)

                fields = fieldnames(app.Model.Prot); fields = fields(end:-1:1);

                N = length(fields);

                for ii = 1:N

                    app.ProtPanels.(fields{ii}).CellSelect = [];

                    % Create PANEL
                    % Panels function as a namespace for protocols.
                    % Unlike options panel, here they are REQUIRED.

                    app.ProtPanels.(fields{ii}).panel = uipanel(app.ProtEditPanel,'Title',fields{ii},'Units','normalized','Position',[.05 (ii-1)*.95/N+.05 .9 .9/N]);
                    app.ProtPanels.(fields{ii}).table = uitable(app.ProtPanels.(fields{ii}).panel,'Data',app.Model.Prot.(fields{ii}).Mat,'Units','normalized','Position',[.05 .08*N .9 (1-.08*N)]);

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

                                uicontrol(app.ProtPanels.(fields{ii}).panel,'Units','normalized','Position',[0.468 0 .066 .061*N],'Style','pushbutton','String','?','BackGroundColor', [0, 0.65, 1],'Callback',@(hObject, eventdata) PointHelp_Callback(app, hObject, eventdata, Tip, fields{ii}));
                            end

                        end

                        % Create BUTTONS
                        uicontrol(app.ProtPanels.(fields{ii}).panel,'Units','normalized','Position',[.03 0.04*N .44 .02*N],'Style','pushbutton','String','Add','Callback',@(hObject, eventdata) PointAdd_Callback(app, hObject, eventdata, fields{ii}));
                        uicontrol(app.ProtPanels.(fields{ii}).panel,'Units','normalized','Position',[.53 0.04*N .44 .02*N],'Style','pushbutton','String','Remove','Callback',@(hObject, eventdata) PointRem_Callback(app, hObject, eventdata, fields{ii}));
                        uicontrol(app.ProtPanels.(fields{ii}).panel,'Units','normalized','Position',[.03 0.02*N .44 .02*N],'Style','pushbutton','String','Move up','Callback',@(hObject, eventdata) PointUp_Callback(app, hObject, eventdata, fields{ii}));
                        uicontrol(app.ProtPanels.(fields{ii}).panel,'Units','normalized','Position',[.53 0.02*N .44 .02*N],'Style','pushbutton','String','Move down','Callback',@(hObject, eventdata) PointDown_Callback(app, hObject, eventdata, fields{ii}));
                        uicontrol(app.ProtPanels.(fields{ii}).panel,'Units','normalized','Position',[.03 0      .44 .02*N],'Style','pushbutton','String','Load','Callback',@(hObject, eventdata) LoadProt_Callback(app, hObject, eventdata, fields{ii}));
                        uicontrol(app.ProtPanels.(fields{ii}).panel,'Units','normalized','Position',[.53 0      .44 .02*N],'Style','pushbutton','String','Create','Callback',@(hObject, eventdata) CreateProt_Callback(app, hObject, eventdata, fields{ii}));
                    end

                    % Make buttons invisible on condition.
                    if isprop(app.Model,'ProtStyle')

                        prot_names  = app.Model.ProtStyle.prot_namespace;
                        styles = {app.Model.ProtStyle.style};
                        [~,prtidx] = ismember(fields{ii},prot_names);

                        if strcmp(styles(prtidx),'TableNoButton') && length(app.ProtPanels.(fields{ii}).panel.Children)>1
                            for chil_iter = 1:length(app.ProtPanels.(fields{ii}).panel.Children)
                                if isa(app.ProtPanels.(fields{ii}).panel.Children(chil_iter),'matlab.ui.control.UIControl')
                                    if strcmp(app.ProtPanels.(fields{ii}).panel.Children(chil_iter).Style,'pushbutton')
                                        app.ProtPanels.(fields{ii}).panel.Children(chil_iter).Visible = 'off';
                                    end
                                end
                            end
                        end
                    end


                end
            end

            if ismethod(app.Model,'plotProt')
                uicontrol(app.ProtEditPanel,'Units','normalized','Position',[.05 0 .9 .05],'Style','pushbutton','String','Plot Protocol','Callback','figure(''color'',''white''), Model = getappdata(0,''Model''); Model.plotProt;');
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
            app.OptionsGUI.Color = [0.902 0.902 0.902];
            colormap(app.OptionsGUI, 'parula');
            app.OptionsGUI.Position = [732 115 573 835];
            app.OptionsGUI.Name = 'OptionsGUI';
            app.OptionsGUI.HandleVisibility = 'on';
            app.OptionsGUI.Tag = 'OptionsGUI';

            % Create uipanel29
            app.uipanel29 = uipanel(app.OptionsGUI);
            app.uipanel29.ForegroundColor = [0 0 0];
            app.uipanel29.Title = 'Options';
            app.uipanel29.BackgroundColor = [0.902 0.902 0.902];
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
            app.Helpbutton.BackgroundColor = [0 0.650980392156863 1];
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