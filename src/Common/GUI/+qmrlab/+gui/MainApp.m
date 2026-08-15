classdef MainApp < matlab.apps.AppBase
%   qMRLab main window.
%
%   Unwrapped from qMRLab.mlapp so the interface is reviewable in a pull request.
%   Launch through qMRLab.m rather than constructing this directly -- that file is
%   the documented entry point and is pinned by mcc, list_models.m and the
%   documentation generator.
%
%   See docs/adr/0001-gui-migration.md.

    % Properties that correspond to app components
    properties (Access = public)
        RootGrid                 matlab.ui.container.GridLayout
        SideGrid                 matlab.ui.container.GridLayout
        FitDataGrid              matlab.ui.container.GridLayout
        ViewerGrid               matlab.ui.container.GridLayout
        ControlGrid              matlab.ui.container.GridLayout
        CompassGrid              matlab.ui.container.GridLayout
        FitPanelGrid             matlab.ui.container.GridLayout
        ViewerHost               matlab.ui.container.Panel
        qMRILab                  matlab.ui.Figure
        Image                    matlab.ui.control.Image
        upgrade_message          matlab.ui.control.Label
        MethodSelection          matlab.ui.control.DropDown
        OpenOptionsPanel         matlab.ui.control.Button
        DefaultMethodBtn         matlab.ui.control.Button
        uipanel37                matlab.ui.container.Panel
        FitGO                    matlab.ui.control.Button
        FitResultsSave           matlab.ui.control.Button
        FitResultsLoad           matlab.ui.control.Button
        SimPanel                 matlab.ui.container.Panel
        SimGO                    matlab.ui.control.Button
        SimLoad                  matlab.ui.control.Button
        SimSave                  matlab.ui.control.Button
        SimRndBtn                matlab.ui.control.Button
        SimVaryBtn               matlab.ui.control.Button
        SimCurveBtn              matlab.ui.control.Button
        FitDataPanel             matlab.ui.container.Panel
        text_doc_model           matlab.ui.control.Label
        CurrentFitId             matlab.ui.control.Label
        text53                   matlab.ui.control.Label
        FitDataFileBrowserPanel  matlab.ui.container.Panel
        FitResultsPlotPanel      matlab.ui.container.Panel
        text80_2                 matlab.ui.control.Label
        ViewROIFit               matlab.ui.control.Button
        Stats                    matlab.ui.control.Button
        txt_OrientS              matlab.ui.control.Label
        txt_OrientI              matlab.ui.control.Label
        txt_OrientR              matlab.ui.control.Label
        txt_OrientL              matlab.ui.control.Label
        text80                   matlab.ui.control.Label
        Viewer                   matlab.ui.control.Button
        text72                   matlab.ui.control.Label
        ViewDataFit              matlab.ui.control.Button
        CursorBtn                matlab.ui.control.StateButton
        SourcePop                matlab.ui.control.DropDown
        ViewPop                  matlab.ui.control.DropDown
        Histogram                matlab.ui.control.Button
        text_version_check       matlab.ui.control.Label
    end

    % Runtime state. Stage F1 promoted these out of the figure's guidata, where
    % they lived as extra fields bolted onto the migration shim's `handles`
    % struct. guidata hands back a COPY, so every mutation had to be followed by
    % a guidata(hObject, handles) to publish it, and anything a second callback
    % wrote while the first was blocked was silently reverted by that write-back.
    % As properties on a handle object there is no copy and nothing to publish.
    properties (Access = public)
        Tool                = []    % the imtool3D viewer. NO type constraint:
                                    % a constrained property with no explicit
                                    % default is default-constructed, and
                                    % imtool3D() with no arguments opens a new
                                    % figure full of random noise.
        CurrentData         = []    % [] until data is loaded, then a struct
        DataCursor          = []    % was dcm_obj: the datacursormode manager
        ModelDir            char    = ''
        DefaultMethodFile   char    = ''   % was Default: path to DefaultMethod.mat
        Opened      (1,1) logical   = false
    end


    methods (Access = private)
        function applyTheme(app)
            % Stage D2. Was ~140 lines: an OS dark-mode probe (a Windows registry
            % query and a macOS `defaults read`), a hand-rolled two-palette colour
            % scheme, and a sweep that painted a named list of ~40 components.
            %
            % All of it is gone because a uifigure themes its own components --
            % measured, an untouched panel goes [0.961] light to [0.129] dark. The
            % sweep existed only to undo the explicit colours the app set on itself
            % a few lines earlier. Delete the colours and there is nothing to undo.
            %
            % What remains is the logo, which is an ASSET and cannot be recoloured.
            qmrlab.gui.Theme.adopt(app.qMRILab);
            % Re-resolve the stamped tokens. adopt() re-themes what MATLAB owns;
            % this reaches what the app paints itself, which otherwise keeps
            % whatever token was current when it was built.
            qmrlab.gui.Theme.repaint(app.qMRILab);
            app.updateLogo();
        end

        function updateLogo(app)
            % The wordmark is dark ink on transparent, so on a dark background it
            % disappears -- visible in Test/GUI/evidence/before_D2_dark_main.png.
            % There is a light/dark pair; pick by the RESOLVED theme rather than by
            % asking the OS again, so the logo cannot disagree with the window.
            root = fileparts(which('qMRLab.m'));
            asset = 'logo_light.png';
            if strcmp(qmrlab.gui.Theme.current(), 'dark')
                if exist(fullfile(root, 'logo_dark.png'), 'file')
                    asset = 'logo_dark.png';
                end
            end
            if isprop(app, 'Image') && ~isempty(app.Image) && isvalid(app.Image)
                app.Image.ImageSource = fullfile(root, asset);
            end
        end

        function FitGo_FitData(app)
            % Original FitGo function


            % Get data
            data =  GetAppData(app, 'Data');
            Method = GetAppData(app, 'Method');
            Model = getappdata(0,'Model');
            if isfield(data,[class(Model) '_hdr']), hdr = data.([class(Model) '_hdr']); end
            data = data.(Method);

            % check data
            ErrMsg = Model.sanityCheck(data);
            if ~isempty(ErrMsg), errordlg(ErrMsg,'Input error','modal'); return; end

            if ~moxunit_util_platform_is_octave

                try
                    p = gcp('nocreate');
                catch
                    p=[];
                end
                if license('test','Distrib_Computing_Toolbox') && Model.voxelwise && isempty(p)
                    cprintf('blue', 'MATLAB detected %d physical cores.',feature('numcores'));
                    cprintf('blue', '<< Tip >> You can accelerate fitting by starting a parallel pool by running: \n parpool(%d);',feature('numcores'));
                    dlgTitle    = 'Parallel Processing';
                    dlgQuestion = sprintf('Would you like to start a parallel pool with %d cores?',feature('numcores'));
                    choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
                    if strcmp(choice,'Yes')
                        parpool(feature('numcores'));
                        p = gcp('nocreate');
                    end
                end

                if ~isempty(p) && Model.voxelwise
                    FitResults = ParFitData(data,Model);
                else
                    FitResults = FitData(data,Model,1);
                end

            else
                % Do the fitting in Octave
                FitResults = FitData(data,Model,1);
            end

            % A fit that reached no voxels -- an empty mask, or one that does not
            % overlap the data -- returns a FitResults with no `fields`. FitData sets
            % that field only inside its first-successful-voxel initialiser on the
            % voxelwise path (the non-voxelwise path assigns it unconditionally).
            %
            % Unguarded, execution ran on to `for ii = 1:length(FitResults.fields)`
            % and died with "Unrecognized field name fields" -- but only AFTER
            % mkdir'ing FitResults_<timestamp> and saving into it, so a failed fit
            % left a junk directory next to the data and a stack trace in the console.
            % Check before anything is written, and say what is actually wrong.
            if ~isfield(FitResults, 'fields') || isempty(FitResults.fields)
                errordlg({'The fit produced no results.', '', ...
                          ['No voxel was fitted. This usually means the mask is empty, ' ...
                           'or does not overlap the data.']}, 'Nothing to fit');
                return;
            end

            % Save info with results
            % FileBrowserList is a struct keyed by method name -- browsers are built
            % lazily as models are selected (see MethodMenu). It used to be an array
            % scanned with IsMethodID, and this site still indexed it that way.
            FileBrowserList = GetAppData(app, 'FileBrowserList');
            browser = FileBrowserList.(Method);

            FitResults.StudyID = browser.getStudyID;
            FitResults.WD = browser.getWD;
            if isempty(FitResults.WD), FitResults.WD = pwd; end
            FitResults.Files = browser.getFileName;
            SetAppData(app, FitResults);

            % Kill the waitbar in case of a problem occurred
            wh=findall(0,'tag','TMWWaitbar');
            delete(wh);

            % convert Model to struct
            FitResults.Model = objProps2struct(FitResults.Model);

            % Save fit results
            if(~isempty(FitResults.StudyID))
                filename = strcat('FitResults_',FitResults.StudyID,'.mat');
            else
                filename = 'FitResults.mat';
            end
            outputdir = fullfile(FitResults.WD,['FitResults_', datestr(datetime('now','TimeZone','local'),'yyyy-mm-dd_HH-MM-SS')]); % ISO 8601 format adapted for MATLAB compatibility
            if ~exist(outputdir,'dir'), mkdir(outputdir);
            else
                iii=1; outputdirnew = outputdir;
                while exist(outputdirnew,'dir')
                    iii=iii+1;
                    outputdirnew = [outputdir,'_' num2str(iii)];
                end
                outputdir = outputdirnew;
                mkdir(outputdir);
            end
            save(fullfile(outputdir,filename),'-struct','FitResults');
            app.CurrentFitId.Text = 'FitResults.mat';

            % Save nii maps
            for ii = 1:length(FitResults.fields)
                map = FitResults.fields{ii};
                file = strcat(map,'.nii.gz');

                if ~exist('hdr','var')
                    save_nii(make_nii(FitResults.(map)),fullfile(outputdir,file));
                else
                    % Reset multiplicative and additive scale factors to nifti header
                    % in case there were some in the input file's header that was used
                    % as a template. If this isn't done, then when a tool loads the
                    % qMRI map's nifti file, it will apply an undesired scaling.
                    hdr.scl_slope = 1;
                    hdr.scl_inter = 0;

                    nii_save(FitResults.(map),hdr,fullfile(outputdir,file));
                end
            end

            SetAppData(app, FileBrowserList);
            % Show results
            app.CurrentData = FitResults;
            if exist('hdr','var')
                app.CurrentData.hdr = hdr;
            end
            DrawPlot(app);
        end

        function varargout = GetAppData(app, varargin)
            % GETAPPDATA - Fixed for App Designer
            % Skip the first argument (app) and process the rest

            nVars = length(varargin);
            varargout = cell(1, nVars);

            for k = 1:nVars
                varargout{k} = getappdata(0, varargin{k});
            end
        end

        function MethodMenu(app, Method)
            % METHODSELECTION


            SetAppData(app, Method)

            % Start by updating the Model object
            if isappdata(0,'Model') && strcmp(class(getappdata(0,'Model')),Method) % if same method, load the current class with parameters
                Model = getappdata(0,'Model');
            else % otherwise create a new object of this method
                Modeltobesaved = getappdata(0,'Model');
                savedModel = getappdata(0,'savedModel');
                savedModel.(class(Modeltobesaved)) = Modeltobesaved;
                setappdata(0,'savedModel',savedModel);
                if isfield(savedModel,Method) && ~isempty(savedModel.(Method))
                    Model = savedModel.(Method);
                else
                    modelfun  = str2func(Method);
                    Model = modelfun();
                end
            end
            SetAppData(app, Model)
            % Create empty Data
            Data = GetAppData(app, 'Data');
            for id=1:length(Model.MRIinputs)
                if isempty(Data) || ~isfield(Data,Method) || ~isfield(Data.(Method),Model.MRIinputs{id})
                    Data.(Method).(Model.MRIinputs{id})=[];
                end
            end
            SetAppData(app, Data);

            % Now create Simulation panel
            % find the Simulation functions of the selected Method
            Methodfun = methods(Method);
            Simfun = Methodfun(~cellfun(@isempty,strfind(Methodfun,'Sim_')));
            % Update Options Panel
            app.SimPanel.Visible = 'off'; % hide the simulation panel for qMT methods
            if isempty(Simfun)
                app.SimPanel.Visible = 'off'; % hide the simulation panel
            else
                app.SimPanel.Visible = 'on'; % show the simulation panel
                delete(setdiff(findobj(app.SimPanel),app.SimPanel))

                N = length(Simfun); %
                Jh = min(0.14,.8/N);
                J=1:max(N,6); J=(J-1)/max(N,6)*0.85; J=1-J-Jh-.01;
                for i = 1:N
                    if exist([Simfun{i} '_GUI'],'file')
                        uicontrol('Style','pushbutton','String',strrep(strrep(Simfun{i},'Sim_',''),'_',' '),...
                            'Parent',app.SimPanel,'Units','normalized','Position',[.04 J(i) .92 Jh],...
                            'HorizontalAlignment','center','FontWeight','bold','Callback',...
                            @(x,y) SimfunGUI(app, [Simfun{i} '_GUI']));
                    end
                end

            end


            % Update Options Panel
            h = findobj('Tag','OptionsGUI');
            if ~isempty(h)
                delete(h);
            end
            Method = app.GetAppData('Method');
            Model = getappdata(0,'Model');
            qmrlab.gui.OptionsWindow(Model, app.qMRILab);


            % Show FileBrowser - with lazy loading
            FileBrowserList = GetAppData(app, 'FileBrowserList');

            % Hide all browsers
            allMethods = fieldnames(FileBrowserList);
            for i = 1:length(allMethods)
                FileBrowserList.(allMethods{i}).Visible('off');
            end

            % Create browser for current method if it doesn't exist
            if ~isfield(FileBrowserList, Method) || isempty(FileBrowserList.(Method))
                Modelfun = str2func(Method);
                Model = Modelfun();
                FileBrowserList.(Method) = MethodBrowser(app.FitDataFileBrowserPanel, Model);
                SetAppData(app, FileBrowserList);
            end

            % Show current method's browser
            FileBrowserList.(Method).Visible('on');

            % Size the Datasets row to the browser that is actually showing.
            %
            % A 'fit' row cannot do this: every model's browser is built once and
            % kept (they are cached in FileBrowserList and merely hidden), so all of
            % them are children of the panel at all times and 'fit' would size to
            % whichever model has the most inputs -- mp2rage's six -- leaving a
            % two-input model with a panel half empty and the viewer needlessly short.
            app.setDatasetsHeight(FileBrowserList.(Method).NbItems);

            % Scale the main panel by a super small factor and
            % bring it back to the original to get rid of
            % artificial duplication of the top portion of the data
            % panel that occurs upon switching to another model
            % after selecting mp2rage.

            % Caused by attachScrollToPanel.

            curpos = app.qMRILab.Position;
            app.qMRILab.Position = curpos.*[1 1 1.0001 1.0001];
            app.qMRILab.Position = curpos;

            % enable/disable viewdatafit
            if ismethod(Model,'plotModel')
                app.ViewDataFit.Enable = 'on';
                app.ViewROIFit.Enable = 'on';
                app.ViewDataFit.Tooltip = 'View fit in a particular voxel';
                app.ViewROIFit.Tooltip = 'View fit in currently selected label';
            else
                app.ViewDataFit.Enable = 'off';
                app.ViewROIFit.Enable = 'off';
                app.ViewDataFit.Tooltip = 'No voxel-wise fitting for this qMR Method (Volume based method)';
            end

            % Content has settled: the Sim buttons, the browser rows and the rebuilt
            % OptionsGUI all just appeared. Scoped to the panels that changed -- a
            % full-figure pass here would grow with the browser cache, which never
            % shrinks (FileBrowserList only hides).
            qmrlab.gui.TypeScale.apply([app.SimPanel, app.FitDataFileBrowserPanel]);
        end

        function SetAppData(app, varargin)
            %SETAPPDATA - Fixed for App Designer
            % Handle both cases: with and without app parameter

            if nargin == 1
                % Only app parameter provided, do nothing
                return;
            end

            % Start from the second argument (skip app)
            for k = 2:nargin
                varName = inputname(k);
                if ~isempty(varName)
                    setappdata(0, varName, varargin{k-1});
                else
                    % Fallback for unnamed variables
                    setappdata(0, ['var_' num2str(k-1)], varargin{k-1});
                end
            end
        end

        function SimfunGUI(app, functionName)
            Model = getappdata(0,'Model');
            SimfunGUI = str2func(functionName);
            SimfunGUI(Model);
        end

        function addModelMenu(app)
            % Display all the options in the popupmenu
            [MethodList, pathmodels] = sct_tools_ls([app.ModelDir filesep '*.m'],0,0,2,1);
            pathmodels = cellfun(@(x) strrep(x,[app.ModelDir filesep],''), pathmodels,'UniformOutput',false);
            if isdeployed
                [MethodList, pathmodels] = qMRLab_static_Models;
            end
            SetAppData(app, MethodList)
            maxlength = max(cellfun(@length,MethodList))+4;
            maxlengthpath = max(cellfun(@length,pathmodels))+2;
            for iM=1:length(MethodList), MethodListfull{iM} = sprintf(['%-' num2str(maxlength) 's%-' num2str(maxlengthpath) 's'],MethodList{iM},['(' strrep(pathmodels{iM},[app.ModelDir filesep],'') ')']); end
            setPopUp(app.MethodSelection, MethodListfull, app.MethodSelection.Value);
            app.MethodSelection.FontName = 'FixedWidth';
            app.MethodSelection.FontWeight = 'bold';
        end

        function txt = dataCursorUpdateFcn(app, h_PointDataTip, event_obj)
            % Customizes text of data tips
            pos = get(event_obj,'Position');
            data = app.Tool.getCurrentImageSlice;

            SourceFields = app.SourcePop.Items;
            Source = SourceFields{app.SourcePop.Value};

            sliceNum = app.Tool.getCurrentSlice;

            txt = {['Source: ', Source],...
                ['[X,Y]: ', '[', num2str(pos(1)), ',', num2str(pos(2)), ']'],...
                ['Slice: ', num2str(sliceNum)],...
                ['Value: ', num2str(data(pos(2), pos(1)))]};
        end




        function hh = plotfit(app, vox)
            Model = GetAppData(app, 'Model');
            % Get data
            data =  getappdata(0,'Data'); data=data.(class(getappdata(0,'Model')));
            S = [size(data.(Model.MRIinputs{1}),1) size(data.(Model.MRIinputs{1}),2) size(data.(Model.MRIinputs{1}),3)];
            Data = app.Tool.getImage(0);
            Scurrent = [size(Data,1) size(Data,2) size(Data,3)];
            datafields = app.SourcePop.Items;

            if sum(S)==0
                helpdlg(['Specify a ' Model.MRIinputs{1} ' file in the filebrowser'])
            elseif ~isequal(Scurrent(1:3), S(1:3))
                Sstr = sprintf('%ix',S);
                Scurstr = sprintf('%ix',Scurrent);
                helpdlg([Model.MRIinputs{1} ' file (' Sstr(1:end-1) ') in the filebrowser is inconsistent with ' datafields{app.SourcePop.Value} ' in the viewer (' Scurstr(1:end-1) '). Load corresponding ' Model.MRIinputs{1} '.'])
                return;
            end

            Model.sanityCheck(data);

            for ipix = 1:length(vox)

                for ii=1:length(Model.MRIinputs)
                    if isfield(data,(Model.MRIinputs{ii})) && ~isempty(data.(Model.MRIinputs{ii}))
                        voltmp = reshape2D(data.(Model.MRIinputs{ii}),4);
                        datasqueeze.(Model.MRIinputs{ii}) = nanmean(voltmp(:,vox{ipix}),2);
                    end
                end
                if isfield(datasqueeze,'Mask'), datasqueeze.Mask = 1; end


                % Create axe
                hh = 68;
                figure(hh)
                h = findobj(hh,'Style','checkbox','String','hold plot in order to compare voxels');
                if ipix==1 && (isempty(h) || ~get(h,'Value'))  % If a data fit check has already been run OR do not hold plot,
                    clf(hh)        % clear the previous data from the figure plot
                    uicontrol('Style','checkbox','String','hold plot in order to compare voxels','Value',0,'Position',[0 0 210 20]);
                end

                haxes = get(hh,'children'); haxes = haxes(strcmp(get(haxes,'Type'),'axes'));

                if ~isempty(haxes)
                    % turn gray old plots
                    for h=1:length(haxes) %might have subplots
                        haxe = get(haxes(h),'children');
                        set(haxe,'Color',[0.8 0.8 0.8]);
                        hAnnotation = get(haxe,'Annotation');
                        % remove their legends
                        for ih=1:length(hAnnotation)
                            if iscell(hAnnotation), hAnnot = hAnnotation{ih}; else hAnnot = hAnnotation; end
                            hLegendEntry = get(hAnnot,'LegendInformation');
                            set(hLegendEntry,'IconDisplayStyle','off');
                        end
                    end
                end
                hold on;

                % Do the fitting
                if ~ismethod(Model,'plotModel'), warndlg('No plotting methods in this model'); return; end
                Fit = Model.fit(datasqueeze) % Display fitting results in command window
                Model.plotModel(Fit,datasqueeze);

                % update legend
                if ~moxunit_util_platform_is_octave
                    legend('Location','best')
                end

            end
        end


    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function qMRLab_OpeningFcn(app, varargin)
            % --- Executes just before qMRLab is made visible.

            % Ensure that the app appears on screen when run
            movegui(app.qMRILab, 'onscreen');

            % Set light/dark theme
            applyTheme(app);


            if max(strcmp(varargin,'wait')), wait=true; varargin(strcmp(varargin,'wait'))=[]; else wait=false; end
            if ~app.Opened % qMRI already opened?
                warning('off','all');
                % Add qMRLab to path
                qMRLabDir = fileparts(which('qMRLab.m'));
                addpath(genpath(qMRLabDir));

                % Do not let this break anything if things go wrong.
                try
                    GUI_animation;
                    cur_ver = qMRLabVer;
                catch
                    cur_ver = qMRLabVer;
                    fprintf('qMRLab version: v%d.%d.%d \n',cur_ver(1),cur_ver(2),cur_ver(3));
                end

                try
                    [verStatus] = versionChecker;
                catch
                    verStatus = [];
                end

                % Display version under qMRLab text
                app.text_version_check.Text = sprintf('v%d.%d.%d',cur_ver(1),cur_ver(2),cur_ver(3));

                % Handle new version message
                % varstatus is empty unless there is a new release.
                if isempty(verStatus)
                    app.upgrade_message.Visible = 'off';
                else
                    app.upgrade_message.Visible = 'on';
                    app.upgrade_message.Text = sprintf('Upgrade to v%d.%d.%d',verStatus(1),verStatus(2),verStatus(3));
                end

                app.Opened = true;
                % startup;
                qMRLabDir = fileparts(which('qMRLab.m'));
                addpath(genpath(qMRLabDir));
                if isdeployed
                    app.DefaultMethodFile = fullfile(qMRLabDir,'DefaultMethod.mat');
                else
                    app.DefaultMethodFile = fullfile(qMRLabDir,'src','Common','Parameters','DefaultMethod.mat');
                    if isempty(getenv('ISAZURE')) || ~str2double(getenv('ISAZURE'))
                        ISAZURE=false;
                    else
                        ISAZURE=true;
                    end
                    if ~ISAZURE
                        if ~license('test', 'Optimization_Toolbox'), error('Optimization Toolbox is not installed on your system: most qMR models won''t fit. Please consider installing <a href="matlab:matlab.internal.language.introspective.showAddon(''OP'');">Optimization Toolbox</a> if you want to use qMRLab in MATLAB.'); end
                        if ~license('test', 'Image_Toolbox'), warning('Image Toolbox is not installed: ROI Analysis tool not available in the GUI. Consider installing <a href="matlab:matlab.internal.language.introspective.showAddon(''IP'');">Image Processing Toolbox</a>'); end
                    end
                end
                app.CurrentData = [];
                app.DataCursor = [];
                MethodList = {}; SetAppData(app, MethodList);
    

                % SET WINDOW AND PANELS
                movegui(app.qMRILab,'center')
                CurrentPos = app.qMRILab.Position;
                NewPos     = CurrentPos;
                NewPos(1)  = CurrentPos(1) - 40;
                app.qMRILab.Position = NewPos;
                % The old `if ispc, set(findobj(...,'Type','uicontrol'),'FontSize',7)`
                % lived here. It was provably dead, not merely unhelpful: it ran
                % BEFORE imtool3D was constructed on the next line, so the panel held
                % only App Designer children and none of them report Type 'uicontrol'.
                % It matched zero objects on Windows for the whole life of the app.
                % 'Small' is the honest, cross-platform, user-owned version of it.
                qmrlab.gui.TypeScale.publish();   % viewer reads this at construction

                % Create viewer.
                %
                % The drawnow is load-bearing, not defensive. imtool3D.m:296 sizes its
                % six inner pixel panels from getpixelposition(parent) AT CONSTRUCTION,
                % and until the first layout pass a grid-child uipanel reports the
                % placeholder 260x221 rather than its real box. The constructor needs
                % >= 60x220 (:297-298 compute pos(3)-2*30 and pos(4)-2*110 with no
                % clamp; only the runtime relayout at :2319 clamps), so the placeholder
                % clears the crash by a single pixel and then lays the viewer out for a
                % window nobody has. drawnow settles the layout of a hidden uifigure,
                % which is exactly the state we are in here.
                drawnow;
                app.Tool = imtool3D(0,[0 0 1 1],app.ViewerHost);

                % One forced relayout. Without a size-change event between construction
                % and first paint, Panels.Image keeps the constructor's pos(4)-2*110
                % instead of the relayout's pos(4)-2*30 and opens 160 px short.
                H = app.Tool.getHandles;
                resizeFcn = get(H.Panels.Large, 'ResizeFcn');
                if ~isempty(resizeFcn)
                    feval(resizeFcn, H.Panels.Large, []);
                end
                H = app.Tool.getHandles;
                set(H.Tools.ViewPlane,'Visible','off')
                set(H.Tools.maskStats,'Visible','off')

                % Fill Menu with models
                app.ModelDir = [qMRLabDir filesep 'src/Models'];
                    addModelMenu(app);
                % Determine the initial method first
                if exist(app.DefaultMethodFile,'file')
                    load(app.DefaultMethodFile);
                else
                    Method = 'inversion_recovery';
                end

                FileBrowserList = GetAppData(app, 'FileBrowserList');
                if isempty(FileBrowserList)
                    % Create empty structure for FileBrowserList
                    FileBrowserList = struct();
                    SetAppData(app, FileBrowserList);
                end

                % Only create FileBrowser for the current method
                if ~isfield(FileBrowserList, Method) || isempty(FileBrowserList.(Method))
                    Modelfun = str2func(Method);
                    Model = Modelfun();
                    FileBrowserList.(Method) = MethodBrowser(app.FitDataFileBrowserPanel, Model);
                    FileBrowserList.(Method).Visible('off');
                    SetAppData(app, FileBrowserList);
                end
            else
                Method = class(GetAppData(app, 'Model'));
            end
            % LOAD INPUT
            if ~isempty(varargin)
                Model = varargin{1};
                SetAppData(app, Model);
                Method = class(Model);
                FileBrowserList = GetAppData(app, 'FileBrowserList');
                if length(varargin)>1
                    data=varargin{2};
                    for ff=fieldnames(data)'
                        FileBrowserList.(Method).setFileName(ff{1}, data.(ff{1}))
                    end
                end
            end

            % Set Menu to method
            MethodList = getappdata(0, 'MethodList');
            indice = find(strcmp(Method,MethodList));
            % find() returns empty when the model is not in the list; setPopUp
            % clamps rather than assigning [] into a validated index.
            setPopUp(app.MethodSelection, app.MethodSelection.Items, indice);


            MethodMenu(app, Method);

            % Wait if output
            if wait
                uiwait(app.qMRILab)
            end



            % View first file
            if length(varargin)>1
                butobj = FileBrowserList.(Method).ItemsList(1);
                butobj.ViewBtn_callback()   % BrowserSet.ViewBtn_callback(obj) takes no extra args
            end

            app.text_doc_model.Text = ['Visit ' Method ' documentation'];

            % Text size. adopt() scales the window now and registers the relayout
            % callback so a later preference change grows the geometry too.
            % Theme BEFORE type: adopt() publishes the colour tokens to root
            % appdata, and the file browser and the vendored viewer read them while
            % they build. Publishing after they exist would leave them on the
            % fallback palette until something forced a repaint.
            qmrlab.gui.Theme.adopt(app.qMRILab);
            qmrlab.gui.Theme.attachMenu(app.qMRILab);
            % Rebuilding the browsers is how a theme change reaches components that
            % read a token at construction. Same teardown MethodMenu already does.
            setappdata(app.qMRILab, 'qmrlabThemeRepaint', @() app.applyTheme());

            qmrlab.gui.TypeScale.adopt(app.qMRILab, @() app.applyTypeGeometry());
            qmrlab.gui.TypeScale.attachMenu(app.qMRILab);

            warning('on','all');
        end

        % Value changed function: CursorBtn
        function CursorBtn_Callback(app, event)

            % Value changed function: CursorBtn
            % CURSOR

            % Get current button state directly from app.CursorBtn
            buttonState = app.CursorBtn.Value;

            if buttonState == 1
                % Button is pressed/down - ENABLE cursor mode
                try

                    if ~isempty(app.Tool)
                        H = app.Tool.getHandles();
                        fig = H.fig;

                        % Create new datacursor object
                        dcm_obj = datacursormode(fig);

                        % Configure it
                        set(dcm_obj, 'Enable', 'on');
                        set(dcm_obj, 'SnapToDataVertex', 'on');
                        set(dcm_obj, 'DisplayStyle', 'datatip');
                        set(dcm_obj, 'UpdateFcn', @app.dataCursorUpdateFcn);

                        % Store it in multiple places for persistence
                        app.DataCursor = dcm_obj;
                        app.qMRILab.UserData.dcm_obj = dcm_obj;
                        setappdata(0, 'dcm_obj', dcm_obj);

                        % Update button text directly using app.CursorBtn
                        app.CursorBtn.Text = 'Selecting...';


                        % Bring figure to front
                        figure(fig);

                        disp('Cursor mode: ON');
                    else
                        errordlg('Image viewer not initialized.');
                        app.CursorBtn.Value = 0; % Reset button
                    end

                catch ME
                    errordlg(['Error: ' ME.message]);
                    app.CursorBtn.Value = 0; % Reset button
                end
            else
                % Button is released/up - DISABLE cursor mode
                try

                    % Check all possible storage locations
                    dcm_to_disable = [];

                    if ~isempty(app.DataCursor)
                        dcm_to_disable = app.DataCursor;
                    elseif isfield(app.qMRILab.UserData, 'dcm_obj')
                        dcm_to_disable = app.qMRILab.UserData.dcm_obj;
                    elseif ~isempty(getappdata(0, 'dcm_obj'))
                        dcm_to_disable = getappdata(0, 'dcm_obj');
                    end

                    if ~isempty(dcm_to_disable)
                        set(dcm_to_disable, 'Enable', 'off');
                        disp('Cursor mode: OFF');
                    end

                    % Update button text directly
                    app.CursorBtn.Text = 'Select';

                catch ME
                    % If error, just update button text
                    app.CursorBtn.Text = 'Select';
                end
            end


        end

        % Button pushed function: DefaultMethodBtn
        function DefaultMethodBtn_Callback(app, event)
            % SET DEFAULT METHODSELECTION


            Method = GetMethod(app);
            setappdata(0, 'Method', Method);
            save(app.DefaultMethodFile,'Method');
        end

        % Button pushed function: FitGO
        function FitGO_Callback(app, event)
            % FITDATA GO


            Method = GetMethod(app);
            setappdata(0, 'Method', Method);
            FitGo_FitData(app);
            % The counterSfMiss variable is assigned by the GetSf.m function
            % to keep track of how many times a warning has been printed.
            % After fit has been completed, we can remove this from the base
            % workspace to avoid confusion.
            if ~evalin('base','exist(''counterSfMiss'')')
                evalin('base','clear(''counterSfMiss'')');
            end
        end

        % Button pushed function: FitResultsLoad
        function FitResultsLoad_Callback(app, event)
            % FITRESULTSLOAD



            [FileName,PathName] = uigetfile({'*FitResults*.mat;*.qmrlab.mat;*.mat'},'FitResults.mat');
            if PathName == 0, return; end
            app.CurrentFitId.Text = FileName;
            FitResults = load(fullfile(PathName,FileName));
            if isfield(FitResults,'Protocol')
                Prot   =  FitResults.Protocol;
            else
                Prot   =  FitResults.Prot;
            end
            if isfield(FitResults,'FitOpt'), FitOpt =  FitResults.FitOpt; SetAppData(app, FitResults, Prot, FitOpt); Method = FitResults.Protocol.Method; end
            if isfield(FitResults,'Model')
                Method = FitResults.Model.ModelName;
                Model = qMRloadObj(FitResults.Model);
                SetAppData(app, FitResults,Model);
            end

            % find model value in the method menu list
            methods = sct_tools_ls([app.ModelDir filesep '*.m'], 0,0,2,1);
            val = find(strcmp(methods,Method));
            setPopUp(app.MethodSelection, app.MethodSelection.Items, val);

            MethodMenu(app, Method)
            FileBrowserList = GetAppData(app, 'FileBrowserList');
            % if isfield(FitResults,'WD'), FileBrowserList.setWD(FitResults.WD); end
            % if isfield(FitResults,'StudyID'), FileBrowserList.setStudyID(FitResults.StudyID); end
            % if isfield(FitResults,'Files'),
            %     for ifile = fieldnames(FitResults.Files)'
            %         FileBrowserList.setFileName(ifile{1},FitResults.Files.(ifile{1}))
            %     end
            % end

            SetAppData(app, FileBrowserList);
            app.CurrentData = FitResults;
            DrawPlot(app);
        end

        % Button pushed function: FitResultsSave
        function FitResultsSave_Callback(app, event)
            % FITRESULTSSAVE


            FitResults = GetAppData(app, 'FitResults');
            [FileName,PathName] = uiputfile('*.mat');
            if PathName == 0, return; end
            save(fullfile(PathName,FileName),'-struct','FitResults');
            app.CurrentFitId.Text = FileName;
        end

        % Button pushed function: Histogram
        function Histogram_Callback(app, event)
            % Delegates to External/imtool3D_td/src/HistogramGUI.m. An older copy of
            % that code used to be inlined here by the migration; master's #523 fixed
            % the shared version (it rendered no controls on R2023b+), so the inlined
            % copy is gone and there is one implementation again.


            Map     = app.Tool.getImage;
            Maskall = app.Tool.getMask(1);
            Color   = app.Tool.getMaskColor;

            SourceFields = app.SourcePop.Items;
            label = SourceFields{app.SourcePop.Value};

            HistogramGUI(Map, Maskall, Color, label)
        end


        % Value changed function: MethodSelection
        function MethodSelection_Callback(app, event)

            Method = GetMethod(app);
            MethodMenu(app, Method);
            app.text_doc_model.Text = ['Visit ' Method ' documentation'];
        end

        % Button pushed function: OpenOptionsPanel
        function OpenOptionsPanel_Callback(app, event)
            % OPEN OPTIONS


            Method = GetAppData(app, 'Method');
            Model = getappdata(0,'Model');
            qmrlab.gui.OptionsWindow(Model, app.qMRILab);
        end

        % Value changed function: SourcePop
        function SourcePop_Callback(app, event)
            % SOURCE


            % unselect button to prevent activation with spacebar
            app.SourcePop.Enable = 'off';
            drawnow;
            app.SourcePop.Enable = 'on';

            app.Tool.setNvol(app.SourcePop.Value);
        end

        % Button pushed function: Stats
        function Stats_Callback(app, event)
            % STATS Table


            app.Stats.Enable = 'off';
            drawnow;
            app.Stats.Enable = 'on';

            I = app.Tool.getImage(1);
            Iraw = app.CurrentData;
            fields = setdiff(Iraw.fields,'Mask','stable')';
            Maskall = app.Tool.getMask(1);
            Color = app.Tool.getMaskColor;
            StatsGUI(I,Maskall, fields, Color);
        end

        % Button pushed function: ViewDataFit
        function ViewDataFit_Callback(app, event)

            % PLOT DATA FIT


            % unselect button to prevent activation with spacebar
            app.ViewDataFit.Enable = 'off';
            drawnow;
            app.ViewDataFit.Enable = 'on';

            % First check if cursor mode is even enabled
            if isempty(app.DataCursor)
                helpdlg('First click the "Select" button to enable cursor mode, then click on a pixel');
                return;
            end

            % Try to get cursor info
            try
                % Check if datacursor is enabled
                if ~strcmp(get(app.DataCursor, 'Enable'), 'on')
                    helpdlg('Cursor mode is not enabled. Click the "Select" button first.');
                    return;
                end

                % Try to get cursor info
                cursorInfo = getCursorInfo(app.DataCursor);

                if isempty(cursorInfo)
                    helpdlg('No cursor selected. Click on a pixel in the image first.');
                    return;
                end

                % Process the cursor info
                info_dcm_all = getCursorInfo(app.DataCursor);
                for ipix = 1:length(info_dcm_all)
                    info_dcm = info_dcm_all(ipix);
                    x = info_dcm.Position(1);
                    y = info_dcm.Position(2);
                    z = app.Tool.getCurrentSlice;
                    S = app.Tool.getImageSize;
                    vox{ipix} = sub2ind(S,y,x,z);
                end
                hh = plotfit(app, vox);
                if ~isempty(hh)
                    set(hh,'Name',['Fitting results of voxel [' num2str([info_dcm.Position(1) info_dcm.Position(2) z]) ']'],'NumberTitle','off');
                    set(hh,'Color',[.94 .94 .94])
                end

            catch ME
                % If getCursorInfo fails, the datacursor might not be properly set up
                helpdlg('Error getting cursor info. Make sure you: 1) Click the "Select" button, 2) Click on a pixel in the image');
                disp(['Error: ' ME.message]);
            end

        end

        % Value changed function: ViewPop
        function ViewPop_Callback(app, event)
            % VIEW


            % unselect button to prevent activation with spacebar
            app.ViewPop.Enable = 'off';
            drawnow;
            app.ViewPop.Enable = 'on';

            UpdateSlice(app)
            View = app.ViewPop.Items;
            if ~iscell(View), View = {View}; end
            app.Tool.setviewplane(View{app.ViewPop.Value})
        end

        % Button pushed function: ViewROIFit
        function ViewROIFit_Callback(app, event)

            % unselect button to prevent activation with spacebar
            app.ViewROIFit.Enable = 'off';
            drawnow;
            app.ViewROIFit.Enable = 'on';

            Mask = app.Tool.getMask();
            if isempty(Mask) || ~any(Mask(:))
                helpdlg('Draw a mask for current label using the brush tools')
                return;
            end

            vox{1} = find(Mask);
            hh = plotfit(app, vox);
            if ~isempty(hh)
                set(hh,'Name',['Fitting results in current label #' num2str(app.Tool.getmaskSelected())],'NumberTitle','off');
                C = app.Tool.getMaskColor();
                set(hh,'Color',[1 1 1]*.8+.2*C(app.Tool.getmaskSelected()+1,:))
            end
        end

        % Button pushed function: Viewer
        function Viewer_Callback(app, event)
            % OPEN VIEWER


            % unselect button to prevent activation with spacebar
            app.Viewer.Enable = 'off';
            drawnow;
            app.Viewer.Enable = 'on';

            I.img = app.Tool.getImage(1);
            I.label = app.SourcePop.Items;
            Mask = app.Tool.getMask(1);
            if isfield(app.CurrentData,'hdr')
                I.hdr = app.CurrentData.hdr;

                tool = imtool3D_nii_3planes(I,Mask);
            else

                tool = imtool3D_3planes(I.img,Mask);

                for ii=1:3, tool(ii).setlabel(I.label); end
            end
            clims = app.Tool.getClimits;
            for ii=1:3
                tool(ii).setNvol(app.Tool.getNvol);
                tool(ii).setClimits(clims);
            end
        end

        % Close request function: qMRILab
        function qMRLab_CloseRequestFcn(app, event)
            % Executes when user attempts to close qMRLab.


            if isequal(get(app.qMRILab, 'waitstatus'), 'waiting')
                % The GUI is still in UIWAIT, us UIRESUME
                uiresume(app.qMRILab);
            else
                AppData = getappdata(0);
                Fields = fieldnames(AppData);
                for k=1:length(Fields)
                    rmappdata(0, Fields{k});
                end
            end
            % The GUI is no longer waiting, just close it
            delete(app.qMRILab);
            h = findobj('Tag','OptionsGUI');
            delete(findobj('Tag','Simu'))
            delete(h);
            wh=findall(0,'tag','TMWWaitbar');
            delete(wh);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function applyTypeGeometry(app)
            % Grow the layout with the text. GROW-ONLY (g >= 1): shrinking would
            % re-expose the sub-minimum overlap D1 clamps against and buys nothing.
            %
            % Container level only. No component Position is multiplied here --
            % the sidebar panels and FitDataPanel keep AutoResizeChildren='on', so
            % their absolutely-positioned children scale proportionally with the
            % column, and the SideGrid cells ('fit' rows) size to their new type.
            % That is what keeps "Set Default" and "Open Options Panel" from
            % clipping at Large, which is the failure every font-only design has.
            g = qmrlab.gui.TypeScale.geomFactor();

            app.RootGrid.ColumnWidth = {270*g, '1x'};
            app.SideGrid.RowHeight   = {90*g, 'fit', 'fit', 'fit', 'fit', 221*g, 351*g, '1x', 'fit'};

            % The two tracks E1/E2 added. Without these the strip and the Datasets
            % rows keep their medium-size cells while the type inside them grows,
            % which is the clipping that gated 'large' in the first place.
            if ~isempty(app.ViewerGrid) && isvalid(app.ViewerGrid)
                app.ViewerGrid.ColumnWidth = {200*g, '1x'};
            end
            if ~isempty(app.FitDataGrid) && isvalid(app.FitDataGrid)
                b = getappdata(0, 'FileBrowserList');
                m = getappdata(0, 'Method');
                if ~isempty(b) && ~isempty(m) && isfield(b, m) && isvalid(b.(m))
                    app.setDatasetsHeight(b.(m).NbItems);
                end
            end

            % Cap the minimum against the monitor: [1126 837]*1.25 is taller than a
            % 1470x956 laptop desktop, and the laptop is exactly where people want
            % larger text. FitDataFileBrowserPanel is Scrollable, so a short window
            % scrolls rather than clipping.
            % Grow the window so the bigger type has somewhere to go. This is not
            % the retired clamp: it fires only when the user CHANGES the text size,
            % and never constrains a resize afterwards. Capped against the monitor --
            % [1126 837]*1.25 is taller than a 1470x956 laptop desktop, and the
            % laptop is exactly where someone wants larger text.
            preferred = min([1126 837]*g, qmrlab.gui.TypeScale.workArea(app.qMRILab));

            pos  = app.qMRILab.Position;
            want = max(pos(3:4), preferred);
            if ~isequal(want, pos(3:4))
                app.qMRILab.Position = [pos(1:2) want];
            end

            % OptionsGUI is absolute-pixel throughout and its option rows are
            % generated from a pixel constant, so it is rebuilt rather than
            % resized. This is the same teardown MethodMenu already performs.
            h = findobj('Tag','OptionsGUI');
            if ~isempty(h)
                delete(h);
                Model = getappdata(0,'Model');
                if ~isempty(Model)
                    qmrlab.gui.OptionsWindow(Model, app.qMRILab);
                end
            end
        end

        function applyResponsiveLayout(app)
            % Replace the fixed pixel layout of the top-level components with a
            % grid, so the window can be resized and so the sidebar keeps a usable
            % width instead of being squashed proportionally.
            %
            % Scoped to the top level on purpose. Everything below FitDataPanel --
            % including the imtool3D viewer -- keeps its own layout: imtool3D
            % positions its children in pixels from its own resize callback, and a
            % uicontrol cannot be a child of a uigridlayout at all. The grid stops
            % at the boundary between native and legacy components.

            app.RootGrid = uigridlayout(app.qMRILab, [1 2]);
            app.RootGrid.ColumnWidth   = {270, '1x'};   % sidebar stays legible, canvas takes the rest
            app.RootGrid.RowHeight     = {'1x'};
            app.RootGrid.Padding       = [8 8 8 8];
            app.RootGrid.ColumnSpacing = 8;

            app.SideGrid = uigridlayout(app.RootGrid, [9 1]);
            app.SideGrid.Layout.Row    = 1;
            app.SideGrid.Layout.Column = 1;
            app.SideGrid.Padding       = [0 0 0 0];
            app.SideGrid.RowSpacing    = 6;
            % The sidebar's fixed rows (logo 90, fit panel 221, sim panel 351, plus
            % the button rows) come to more than a short window has. At 1280x800 --
            % an ordinary laptop -- SimPanel hung 23 px below the grid. Found only
            % once E4 removed windowSurvivesResize's exemption from the full-tree
            % audit; the clamp had kept the window tall enough to hide it.
            app.SideGrid.Scrollable    = 'on';
            % 'fit' rows size to their content. The two panels keep their design
            % heights -- they hold absolutely-positioned children, so stretching them
            % just opens a gap above the buttons rather than distributing anything.
            % A '1x' spacer absorbs the slack and pins Open Options Panel to the
            % bottom, where the layout has it.
            app.SideGrid.RowHeight = {90, 'fit', 'fit', 'fit', 'fit', 221, 351, '1x', 'fit'};

            sidebar = { app.Image, app.text_version_check, app.upgrade_message, ...
                        app.MethodSelection, app.DefaultMethodBtn, app.uipanel37, ...
                        app.SimPanel, [], app.OpenOptionsPanel };
            for k = 1:numel(sidebar)
                h = sidebar{k};
                if isempty(h) || ~isvalid(h), continue; end   % k == 8 is the spacer
                h.Parent = app.SideGrid;
                h.Layout.Row = k;
                h.Layout.Column = 1;
            end

            app.FitDataPanel.Parent = app.RootGrid;
            app.FitDataPanel.Layout.Row = 1;
            app.FitDataPanel.Layout.Column = 2;

            app.buildFitDataGrid();

            % Models with many inputs (mp2rage has 5, mt_sat and qmt_spgr 4 each) build
            % more data rows than fit at the panel's design height, and the rows below
            % the fold were simply clipped. GUIDE papered over this with
            % attachScrollPanelTo, a JavaFrame/JScrollPane hack that has been dead
            % since R2021a and whose own header says it does not work with uifigure.
            % Scrollable is the supported replacement, and it is one property.
            % Scroll ownership sits with each MethodBrowser's grid now (E2), not
            % with this panel. Nesting one scroller inside another gives two
            % scrollbars for one overflow.
            app.FitDataFileBrowserPanel.Scrollable = 'off';

            % FitDataPanel's own children are now grid cells (buildFitDataGrid), so
            % AutoResizeChildren no longer has anything to act on here.
            %
            % Correcting the claim the D1 commit left in this spot -- it said the
            % absolutely-positioned children "scale proportionally with the column".
            % They do not. Measured on R2026b: AutoResizeChildren is a pure TOP-ANCHOR
            % TRANSLATION. Every child's y shifts by exactly the container's height
            % delta while x, width and height are untouched (a panel taken from
            % 900x700 to 1800x891 moved all four probe children dy=+191, dx=dw=dh=0).
            % That is why widening the window never widened anything inside it, and
            % why a grid -- which resizes its cells directly -- is the fix rather than
            % a property.
            app.FitDataPanel.AutoResizeChildren = 'off';

            % The logo is an image: let it scale within its cell rather than being
            % clipped, which is what produced the truncated "qMRI ah" wordmark.
            if isprop(app.Image, 'ScaleMethod')
                app.Image.ScaleMethod = 'fit';
            end

            % The window may grow freely, but not shrink below the size its content
            % was authored for. Inside FitDataPanel the data browser and the viewer
            % toolbar are still laid out in pixels by code that runs at runtime, so
            % below the design width they overlap rather than reflow. Stage E moves
            % those generators onto grids; until then, clamp.
            % Stage E4: no minimum-size clamp.
            %
            % It existed because the data browser and the viewer toolbar were laid
            % out in pixels at runtime and overlapped below the design size. E1 and
            % E2 put both on grids, so measured with the clamp disabled the window is
            % audit-clean down to 1000x750, and below that the only thing that
            % overflows is the viewer's control strip -- which now scrolls, like the
            % browser. The window may be any size the user wants.
            app.qMRILab.Resize = 'on';
            app.qMRILab.AutoResizeChildren = 'off';
        end

        function buildFitDataGrid(app)
            % Stage E1. Put FitDataPanel's contents on a grid, and the viewer pane's
            % control strip on one too.
            %
            % WHY: growing the window used to add dead space. D1 gridded the top
            % level, so FitDataPanel's COLUMN grew, but its children kept their
            % design size -- AutoResizeChildren only translates them downward, it
            % does not resize them (see applyResponsiveLayout). Both of these
            % children are containers, so they are legal grid children, and a grid
            % resizes them DIRECTLY.
            %
            % It also retires a defect the old split was hiding. imtool3D was
            % parented straight into FitResultsPlotPanel at a normalized
            % [0.25 0 .75 1], and that split stops being honoured after the first
            % resize: measured at 900x520, Panels.Large came out 605 px wide inside a
            % 617 px FitResultsPlotPanel -- 98% of the pane, not 75% -- covering the
            % left quarter where the control strip lives. The strip was still there,
            % just underneath the viewer. The min-size clamp was holding the window
            % above the size where that became obvious; E4 retired it.

            % --- FitDataPanel: browser on top, viewer below, status line at the foot.
            app.FitDataGrid = uigridlayout(app.FitDataPanel, [3 3]);
            % Row 1 keeps the browser's design height on purpose: MethodBrowser still
            % positions its rows in pixels measured from this panel at construction
            % time, so changing the height here would move them. E2 grids the browser
            % and this row becomes 'fit'.
            app.FitDataGrid.RowHeight   = {189, '1x', 'fit'};
            app.FitDataGrid.ColumnWidth = {'fit', '1x', 'fit'};
            app.FitDataGrid.Padding     = [6 4 6 4];
            app.FitDataGrid.RowSpacing  = 4;

            place(app.FitDataFileBrowserPanel, app.FitDataGrid, 1, [1 3]);
            place(app.FitResultsPlotPanel,     app.FitDataGrid, 2, [1 3]);
            place(app.text53,                  app.FitDataGrid, 3, 1);
            place(app.CurrentFitId,            app.FitDataGrid, 3, 2);
            place(app.text_doc_model,          app.FitDataGrid, 3, 3);

            % --- The Fit panel's three buttons.
            %
            % Not one of the two areas TypeScale's gate named, but the same defect:
            % at the 1.25 step "Save Results" and "Load Results" grew until the text
            % touched the button edges. A grid gives them cells that grow with the
            % type. Fit data keeps the visual weight it had -- a wide button across
            % the top -- via the 2:1 row split.
            app.FitPanelGrid = uigridlayout(app.uipanel37, [2 2]);
            app.FitPanelGrid.RowHeight     = {'2x', '1x'};
            app.FitPanelGrid.ColumnWidth   = {'1x', '1x'};
            app.FitPanelGrid.Padding       = [10 10 10 10];
            app.FitPanelGrid.RowSpacing    = 8;
            app.FitPanelGrid.ColumnSpacing = 8;
            place(app.FitGO,          app.FitPanelGrid, 1, [1 2]);
            place(app.FitResultsSave, app.FitPanelGrid, 2, 1);
            place(app.FitResultsLoad, app.FitPanelGrid, 2, 2);

            % --- FitResultsPlotPanel: control strip | viewer.
            app.FitResultsPlotPanel.AutoResizeChildren = 'off';
            app.ViewerGrid = uigridlayout(app.FitResultsPlotPanel, [1 2]);
            app.ViewerGrid.ColumnWidth   = {200, '1x'};
            app.ViewerGrid.RowHeight     = {'1x'};
            app.ViewerGrid.Padding       = [4 4 4 4];
            app.ViewerGrid.ColumnSpacing = 6;

            % The strip's reading order is taken from the coordinates it had, not
            % invented: Volume / source, view + 3D viewer, Quality Assurance, the two
            % fit buttons, the two analysis buttons, Cursor, Select, and the
            % orientation compass. The trailing '1x' absorbs the slack so the controls
            % stay at the top instead of spreading down a tall pane.
            app.ControlGrid = uigridlayout(app.ViewerGrid, [10 2]);
            app.ControlGrid.Layout.Row    = 1;
            app.ControlGrid.Layout.Column = 1;
            app.ControlGrid.RowHeight     = [repmat({'fit'}, 1, 9), {'1x'}];
            app.ControlGrid.ColumnWidth   = {'1x', '1x'};
            app.ControlGrid.Padding       = [0 0 0 0];
            app.ControlGrid.RowSpacing    = 6;
            app.ControlGrid.ColumnSpacing = 6;
            % The strip's controls come to ~460 px and cannot compress. Measured with
            % the clamp disabled, that is the one thing that still overflowed below
            % 1000x750: the strip hung off the bottom of the viewer pane and by
            % 800x600 was entirely off the figure. Scrolling is what lets E4 retire
            % the clamp instead of the clamp hiding this.
            app.ControlGrid.Scrollable    = 'on';

            place(app.text80_2,    app.ControlGrid, 1, [1 2]);   % 'Volume'
            place(app.SourcePop,   app.ControlGrid, 2, [1 2]);
            place(app.ViewPop,     app.ControlGrid, 3, 1);
            place(app.Viewer,      app.ControlGrid, 3, 2);       % '3D viewer'
            place(app.text80,      app.ControlGrid, 4, [1 2]);   % 'Quality Assurance'
            place(app.ViewDataFit, app.ControlGrid, 5, 1);
            place(app.Stats,       app.ControlGrid, 5, 2);
            place(app.ViewROIFit,  app.ControlGrid, 6, 1);
            place(app.Histogram,   app.ControlGrid, 6, 2);
            place(app.text72,      app.ControlGrid, 7, [1 2]);   % 'Cursor'
            place(app.CursorBtn,   app.ControlGrid, 8, [1 2]);   % 'Select'

            % The compass is a shape, not a list: S above, L and R either side, I below.
            app.CompassGrid = uigridlayout(app.ControlGrid, [3 3]);
            app.CompassGrid.Layout.Row    = 9;
            app.CompassGrid.Layout.Column = [1 2];
            app.CompassGrid.RowHeight     = {'fit', 'fit', 'fit'};
            app.CompassGrid.ColumnWidth   = {'1x', '1x', '1x'};
            app.CompassGrid.Padding       = [0 0 0 0];
            app.CompassGrid.RowSpacing    = 0;
            app.CompassGrid.ColumnSpacing = 0;
            place(app.txt_OrientS, app.CompassGrid, 1, 2);
            place(app.txt_OrientL, app.CompassGrid, 2, 1);
            place(app.txt_OrientR, app.CompassGrid, 2, 3);
            place(app.txt_OrientI, app.CompassGrid, 3, 2);
            % These four carried an explicit [0.94 0.94 0.94] that was invisible only
            % because the old grey pane happened to match it. On the white pane each
            % letter became a grey box. They are labels on a background, not chips:
            % 'none' is what they always meant, and it is one fewer explicit colour
            % for D2 to strip.
            set([app.txt_OrientS app.txt_OrientL app.txt_OrientR app.txt_OrientI], ...
                'BackgroundColor', 'none');

            % --- The viewer's host.
            %
            % imtool3D goes into a PLAIN UIPANEL that is the grid's cell, never into
            % the GridLayout itself. Measured, both matter:
            %
            %   * A GridLayout parent silently discards imtool3D's 'Position',[0 0 1 1]
            %     (MATLAB:ui:components:noPositionSetWhenInLayoutContainer), auto-places
            %     the panel in some other cell, and -- because its SizeChangedFcn then
            %     fires mid-layout-pass, when the size is not yet knowable -- relayouts
            %     to a stale size. The mask rail drifted between +280 and -278 px.
            % AutoResizeChildren is 'off' because that is what a container holding a
            % single self-managing child should say, and because imtool3D sets exactly
            % the same on its own Panels.Large.
            %
            % Being precise about the evidence, because it is easy to overstate: in an
            % isolated harness, a grid-child panel left at the default 'on' had the
            % normalized Position of its [0 0 1 1] child rewritten by MATLAB to values
            % over 1, overflowing the column by 139 px -- reproduced with an empty
            % panel and no imtool3D, so it is MATLAB's behaviour. It does NOT reproduce
            % in this app: measured here at five window sizes, 'on' and 'off' give
            % byte-identical geometry (Panels.Large equals its host exactly either
            % way). So this is the defensible setting, not a load-bearing one, and no
            % test can currently tell the two apart.
            app.ViewerHost = uipanel(app.ViewerGrid);
            app.ViewerHost.Layout.Row         = 1;
            app.ViewerHost.Layout.Column      = 2;
            app.ViewerHost.Tag                = 'ViewerHost';
            app.ViewerHost.BorderType         = 'none';
            app.ViewerHost.AutoResizeChildren = 'off';
            % No BackgroundColor. Reading a themed colour and re-stating it makes
            % it EXPLICIT, which is exactly what D2 removed everywhere else -- and
            % this line survived because it never mentions a literal. Measured: it
            % froze at [0.961], so in dark mode a light-grey slab framed the viewer
            % inside a [0.129] pane. Inheriting is what was wanted all along.

            function place(h, grid, row, col)
                if isempty(h) || ~isvalid(h), return; end
                h.Parent = grid;
                h.Layout.Row = row;
                h.Layout.Column = col;
            end
        end

        function chrome = browserChrome(app)
            % Height the Datasets PANEL spends on itself -- its title band and
            % border -- so heightFor's CONTENT estimate can be turned into a panel
            % height.
            %
            % This is why the "Cannot find required input called ..." warning was
            % clipped. heightFor returns what the browser's grid needs; the result
            % was assigned straight to FitDataGrid.RowHeight{1}, which sizes the
            % panel. The content was therefore always over by the title band, and
            % the last row -- the warning -- fell off the bottom. Same
            % inner-vs-outer trap ADR D10 records for character units.
            %
            % Position(4) - InnerPosition(4), NOT the panel height minus the grid
            % height. The grid's rows are 'fit', so it is only ever as tall as its
            % content; measuring against it makes the answer depend on the very
            % thing being sized, and each call then adds the previous call's slack
            % (measured: the track ran 139 -> 228 px over successive resizes).
            % InnerPosition is a property of the panel alone, and it already tracks
            % the title font -- measured 13 px at the default size, 21 px at
            % FontSize 20 -- so it stays correct across the text-size preference,
            % which a hardcoded constant would not.
            chrome = 14;
            try
                panel = app.FitDataFileBrowserPanel;
                if isvalid(panel) && isprop(panel, 'InnerPosition')
                    d = panel.Position(4) - panel.InnerPosition(4);
                    if d > 0 && d < 120, chrome = d; end
                end
            catch
                % keep the default
            end
        end

        function setDatasetsHeight(app, nItems)
            % Give the Datasets row what the active browser needs, but never more
            % than half the pane -- the viewer is the reason the window is open. Past
            % that the browser's own grid scrolls, which is why it is Scrollable.
            if isempty(app.FitDataGrid) || ~isvalid(app.FitDataGrid), return; end
            want = MethodBrowser.heightFor(nItems) + app.browserChrome();
            pane = getpixelposition(app.FitDataPanel);
            if pane(4) > 100
                want = min(want, round(pane(4) * 0.5));
            end
            app.FitDataGrid.RowHeight{1} = want;
        end

        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(which('qMRLab.m'));

            % Create qMRILab and hide until all components are created
            app.qMRILab = uifigure('Visible', 'off');
            colormap(app.qMRILab, 'parula');
            app.qMRILab.Position = [283 -771 1126 837];
            app.qMRILab.Name = 'qMRLab';
            app.qMRILab.CloseRequestFcn = createCallbackFcn(app, @qMRLab_CloseRequestFcn, true);
            app.qMRILab.HandleVisibility = 'on';
            app.qMRILab.Tag = 'qMRILab';

            % Create text_version_check
            app.text_version_check = uilabel(app.qMRILab);
            app.text_version_check.Tag = 'text_version_check';
            app.text_version_check.HorizontalAlignment = 'center';
            app.text_version_check.VerticalAlignment = 'top';
            app.text_version_check.WordWrap = 'on';
            app.text_version_check.FontSize = 16;
            app.text_version_check.Position = [36 722 210.026666666667 25.0666666666667];
            app.text_version_check.Text = 'vx.y.z';

            % Create FitDataPanel
            app.FitDataPanel = uipanel(app.qMRILab);
            app.FitDataPanel.Title = 'Fit qMRI Data';
            app.FitDataPanel.Tag = 'FitDataPanel';
            app.FitDataPanel.FontWeight = 'bold';
            app.FitDataPanel.FontSize = 13.3333333333332;
            app.FitDataPanel.Position = [278 11 835 813];

            % Create FitResultsPlotPanel
            app.FitResultsPlotPanel = uipanel(app.FitDataPanel);
            app.FitResultsPlotPanel.Title = 'Image Viewer';
            app.FitResultsPlotPanel.Tag = 'FitResultsPlotPanel';
            app.FitResultsPlotPanel.FontSize = 13.3333333333331;
            app.FitResultsPlotPanel.Position = [12 25 811 566];

            % Create Histogram
            app.Histogram = uibutton(app.FitResultsPlotPanel, 'push');
            app.Histogram.ButtonPushedFcn = createCallbackFcn(app, @Histogram_Callback, true);
            app.Histogram.Tag = 'Histogram';
            app.Histogram.FontSize = 13.3333333333332;
            app.Histogram.Position = [106 355 78 25];
            app.Histogram.Text = 'Histogram';

            % Create ViewPop
            app.ViewPop = uidropdown(app.FitResultsPlotPanel);
            app.ViewPop.Items = {'Axial'};
            app.ViewPop.ValueChangedFcn = createCallbackFcn(app, @ViewPop_Callback, true);
            app.ViewPop.Tag = 'ViewPop';
            app.ViewPop.FontSize = 13.3333333333332;
            app.ViewPop.Position = [13 469 78 25];
            % ItemsData makes Value an index rather than the item's text; see
            % setPopUp. Seeded here so the FIRST read is already an index.
            app.ViewPop.ItemsData = 1;
            app.ViewPop.Value = 1;

            % Create SourcePop
            app.SourcePop = uidropdown(app.FitResultsPlotPanel);
            app.SourcePop.Items = {};
            app.SourcePop.ValueChangedFcn = createCallbackFcn(app, @SourcePop_Callback, true);
            app.SourcePop.Tag = 'SourcePop';
            app.SourcePop.FontSize = 13.3333333333332;
            app.SourcePop.Position = [13 502 171 19];
            app.SourcePop.ItemsData = [];
            app.SourcePop.Value = {};

            % Create CursorBtn
            app.CursorBtn = uibutton(app.FitResultsPlotPanel, 'state');
            app.CursorBtn.ValueChangedFcn = createCallbackFcn(app, @CursorBtn_Callback, true);
            app.CursorBtn.Tag = 'CursorBtn';
            app.CursorBtn.Text = 'Select';
            app.CursorBtn.FontSize = 13.3333333333332;
            app.CursorBtn.Position = [61 272 78 25];

            % Create ViewDataFit
            app.ViewDataFit = uibutton(app.FitResultsPlotPanel, 'push');
            app.ViewDataFit.ButtonPushedFcn = createCallbackFcn(app, @ViewDataFit_Callback, true);
            app.ViewDataFit.Tag = 'ViewDataFit';
            app.ViewDataFit.FontSize = 13.3333333333332;
            app.ViewDataFit.Position = [13 383 78 25];
            app.ViewDataFit.Text = 'Voxel fit';

            % Create text72
            app.text72 = uilabel(app.FitResultsPlotPanel);
            app.text72.Tag = 'text72';
            app.text72.HorizontalAlignment = 'center';
            app.text72.VerticalAlignment = 'top';
            app.text72.WordWrap = 'on';
            app.text72.FontSize = 13.3333333333332;
            app.text72.FontWeight = 'bold';
            app.text72.Position = [66 306 65.8303691770152 17.8798269710461];
            app.text72.Text = 'Cursor';

            % Create Viewer
            app.Viewer = uibutton(app.FitResultsPlotPanel, 'push');
            app.Viewer.ButtonPushedFcn = createCallbackFcn(app, @Viewer_Callback, true);
            app.Viewer.Tag = 'Viewer';
            app.Viewer.FontSize = 13.3333333333332;
            app.Viewer.Position = [106 469 78 25];
            app.Viewer.Text = '3D viewer';

            % Create text80
            app.text80 = uilabel(app.FitResultsPlotPanel);
            app.text80.Tag = 'text80';
            app.text80.HorizontalAlignment = 'center';
            app.text80.VerticalAlignment = 'top';
            app.text80.WordWrap = 'on';
            app.text80.FontSize = 13.3333333333332;
            app.text80.FontWeight = 'bold';
            app.text80.Position = [38 398 123 38];
            app.text80.Text = 'Quality Assurance';

            % Create txt_OrientL
            app.txt_OrientL = uilabel(app.FitResultsPlotPanel);
            app.txt_OrientL.Tag = 'txt_OrientL';
            app.txt_OrientL.HorizontalAlignment = 'center';
            app.txt_OrientL.VerticalAlignment = 'top';
            app.txt_OrientL.WordWrap = 'on';
            app.txt_OrientL.FontSize = 13.3333333333333;
            app.txt_OrientL.FontWeight = 'bold';
            app.txt_OrientL.Position = [73 226 18.2299483874811 16.9858356224938];
            app.txt_OrientL.Text = 'L';

            % Create txt_OrientR
            app.txt_OrientR = uilabel(app.FitResultsPlotPanel);
            app.txt_OrientR.Tag = 'txt_OrientR';
            app.txt_OrientR.HorizontalAlignment = 'center';
            app.txt_OrientR.VerticalAlignment = 'top';
            app.txt_OrientR.WordWrap = 'on';
            app.txt_OrientR.FontSize = 13.3333333333333;
            app.txt_OrientR.FontWeight = 'bold';
            app.txt_OrientR.Position = [111 226 18.2299483874811 16.9858356224938];
            app.txt_OrientR.Text = 'R';

            % Create txt_OrientI
            app.txt_OrientI = uilabel(app.FitResultsPlotPanel);
            app.txt_OrientI.Tag = 'txt_OrientI';
            app.txt_OrientI.HorizontalAlignment = 'center';
            app.txt_OrientI.VerticalAlignment = 'top';
            app.txt_OrientI.WordWrap = 'on';
            app.txt_OrientI.FontSize = 13.3333333333333;
            app.txt_OrientI.FontWeight = 'bold';
            app.txt_OrientI.Position = [89 209 21 17];
            app.txt_OrientI.Text = 'I';

            % Create txt_OrientS
            app.txt_OrientS = uilabel(app.FitResultsPlotPanel);
            app.txt_OrientS.Tag = 'txt_OrientS';
            app.txt_OrientS.HorizontalAlignment = 'center';
            app.txt_OrientS.VerticalAlignment = 'top';
            app.txt_OrientS.WordWrap = 'on';
            app.txt_OrientS.FontSize = 13.3333333333333;
            app.txt_OrientS.FontWeight = 'bold';
            app.txt_OrientS.Position = [88 242 22.2810480291436 16.9858356224938];
            app.txt_OrientS.Text = 'S';

            % Create Stats
            app.Stats = uibutton(app.FitResultsPlotPanel, 'push');
            app.Stats.ButtonPushedFcn = createCallbackFcn(app, @Stats_Callback, true);
            app.Stats.Tag = 'Stats';
            app.Stats.FontSize = 13.3333333333332;
            app.Stats.Position = [106 383 78 25];
            app.Stats.Text = 'Statistics';

            % Create ViewROIFit
            app.ViewROIFit = uibutton(app.FitResultsPlotPanel, 'push');
            app.ViewROIFit.ButtonPushedFcn = createCallbackFcn(app, @ViewROIFit_Callback, true);
            app.ViewROIFit.Tag = 'ViewROIFit';
            app.ViewROIFit.FontSize = 13.3333333333332;
            app.ViewROIFit.Position = [13 355 78 25];
            app.ViewROIFit.Text = 'ROI fit';

            % Create text80_2
            app.text80_2 = uilabel(app.FitResultsPlotPanel);
            % Was 'text80', colliding with app.text80 above. The collision
            % mattered because the GUIDE shim keyed its handles struct by Tag, so
            % one of the two simply did not exist there. The shim is gone as of
            % F1, but the Tag must stay unique regardless:
            % findall(fig,'Tag','text80') returned both, and the tests and the
            % wiring audit look components up that way.
            app.text80_2.Tag = 'text80_2';
            app.text80_2.HorizontalAlignment = 'center';
            app.text80_2.VerticalAlignment = 'top';
            app.text80_2.WordWrap = 'on';
            app.text80_2.FontSize = 13.3333333333332;
            app.text80_2.FontWeight = 'bold';
            app.text80_2.Position = [30 523 140 18];
            app.text80_2.Text = 'Volume';

            % Create FitDataFileBrowserPanel
            app.FitDataFileBrowserPanel = uipanel(app.FitDataPanel);
            app.FitDataFileBrowserPanel.Title = 'Datasets';
            app.FitDataFileBrowserPanel.Tag = 'FitDataFileBrowserPanel';
            app.FitDataFileBrowserPanel.FontSize = 13.3333333333332;
            app.FitDataFileBrowserPanel.Position = [12 594 811 189];

            % Create text53
            app.text53 = uilabel(app.FitDataPanel);
            app.text53.Tag = 'text53';
            app.text53.VerticalAlignment = 'top';
            app.text53.WordWrap = 'on';
            app.text53.FontSize = 13.3333333333333;
            app.text53.Position = [14 7 101.865773310999 16.4660801564027];
            app.text53.Text = 'Current file :';

            % Create CurrentFitId
            app.CurrentFitId = uilabel(app.FitDataPanel);
            app.CurrentFitId.Tag = 'CurrentFitId';
            app.CurrentFitId.VerticalAlignment = 'top';
            app.CurrentFitId.WordWrap = 'on';
            app.CurrentFitId.FontSize = 13.3333333333333;
            app.CurrentFitId.Position = [101 7 723.118781725888 16.2751690821256];
            app.CurrentFitId.Text = '';

            % Create text_doc_model
            app.text_doc_model = uilabel(app.FitDataPanel);
            app.text_doc_model.Tag = 'text_doc_model';
            app.text_doc_model.HorizontalAlignment = 'right';
            app.text_doc_model.VerticalAlignment = 'top';
            app.text_doc_model.WordWrap = 'on';
            app.text_doc_model.FontSize = 13.3333333333333;
            app.text_doc_model.FontWeight = 'bold';
            qmrlab.gui.Theme.paint(app.text_doc_model, 'FontColor', 'accent');
            app.text_doc_model.Position = [554 2 268 22];
            app.text_doc_model.Text = 'Click here for user documentation';

            % Create SimPanel
            app.SimPanel = uipanel(app.qMRILab);
            app.SimPanel.TitlePosition = 'centertop';
            app.SimPanel.Title = 'Simulation tools';
            app.SimPanel.Tag = 'SimPanel';
            app.SimPanel.FontWeight = 'bold';
            app.SimPanel.FontSize = 16;
            app.SimPanel.Position = [15 64 252 351];

            % Create SimCurveBtn
            app.SimCurveBtn = uibutton(app.SimPanel, 'push');
            app.SimCurveBtn.Tag = 'SimCurveBtn';
            app.SimCurveBtn.FontSize = 13.3333333333333;
            app.SimCurveBtn.FontWeight = 'bold';
            app.SimCurveBtn.Position = [13 265 227 43];
            app.SimCurveBtn.Text = 'Single Voxel Curve';

            % Create SimVaryBtn
            app.SimVaryBtn = uibutton(app.SimPanel, 'push');
            app.SimVaryBtn.Tag = 'SimVaryBtn';
            app.SimVaryBtn.FontSize = 13.3333333333333;
            app.SimVaryBtn.FontWeight = 'bold';
            app.SimVaryBtn.Position = [13 213 227 43];
            app.SimVaryBtn.Text = 'Sensitivity Analysis';

            % Create SimRndBtn
            app.SimRndBtn = uibutton(app.SimPanel, 'push');
            app.SimRndBtn.Tag = 'SimRndBtn';
            app.SimRndBtn.FontSize = 13.3333333333333;
            app.SimRndBtn.FontWeight = 'bold';
            app.SimRndBtn.Position = [13 161 227 43];
            app.SimRndBtn.Text = 'Multi Voxel Distribution';

            % Create SimSave
            app.SimSave = uibutton(app.SimPanel, 'push');
            app.SimSave.Tag = 'SimSave';
            app.SimSave.FontSize = 13.3333333333333;
            app.SimSave.FontWeight = 'bold';
            app.SimSave.Position = [13 6 109 38];
            app.SimSave.Text = 'Save Results';

            % Create SimLoad
            app.SimLoad = uibutton(app.SimPanel, 'push');
            app.SimLoad.Tag = 'SimLoad';
            app.SimLoad.FontSize = 13.3333333333333;
            app.SimLoad.FontWeight = 'bold';
            app.SimLoad.Position = [132 6 108 38];
            app.SimLoad.Text = 'Load Results';

            % Create SimGO
            app.SimGO = uibutton(app.SimPanel, 'push');
            app.SimGO.Tag = 'SimGO';
            qmrlab.gui.Theme.paint(app.SimGO, 'BackgroundColor', 'warning');
            qmrlab.gui.Theme.paint(app.SimGO, 'FontColor', 'onTheAccent');
            app.SimGO.FontSize = 18.6666666666666;
            app.SimGO.FontWeight = 'bold';
            app.SimGO.Position = [13 55 227 86];
            app.SimGO.Text = 'Simulate data';

            % Create uipanel37
            app.uipanel37 = uipanel(app.qMRILab);
            app.uipanel37.BorderType = 'none';
            app.uipanel37.Tag = 'uipanel37';
            app.uipanel37.FontWeight = 'bold';
            app.uipanel37.FontSize = 16;
            app.uipanel37.Position = [14 416 252 221];

            % Create FitResultsLoad
            app.FitResultsLoad = uibutton(app.uipanel37, 'push');
            app.FitResultsLoad.ButtonPushedFcn = createCallbackFcn(app, @FitResultsLoad_Callback, true);
            app.FitResultsLoad.Tag = 'FitResultsLoad';
            app.FitResultsLoad.FontSize = 13.3333333333332;
            app.FitResultsLoad.FontWeight = 'bold';
            app.FitResultsLoad.Position = [133 18 109 62];
            app.FitResultsLoad.Text = 'Load Results';

            % Create FitResultsSave
            app.FitResultsSave = uibutton(app.uipanel37, 'push');
            app.FitResultsSave.ButtonPushedFcn = createCallbackFcn(app, @FitResultsSave_Callback, true);
            app.FitResultsSave.Tag = 'FitResultsSave';
            app.FitResultsSave.FontSize = 13.3333333333332;
            app.FitResultsSave.FontWeight = 'bold';
            app.FitResultsSave.Position = [14 18 108 62];
            app.FitResultsSave.Text = 'Save Results';

            % Create FitGO
            app.FitGO = uibutton(app.uipanel37, 'push');
            app.FitGO.ButtonPushedFcn = createCallbackFcn(app, @FitGO_Callback, true);
            app.FitGO.Tag = 'FitGO';
            qmrlab.gui.Theme.paint(app.FitGO, 'BackgroundColor', 'accent');
            qmrlab.gui.Theme.paint(app.FitGO, 'FontColor', 'onTheAccent');
            app.FitGO.FontSize = 18.6666666666665;
            app.FitGO.FontWeight = 'bold';
            app.FitGO.Position = [14 95 227 90];
            app.FitGO.Text = 'Fit data';

            % Create DefaultMethodBtn
            app.DefaultMethodBtn = uibutton(app.qMRILab, 'push');
            app.DefaultMethodBtn.ButtonPushedFcn = createCallbackFcn(app, @DefaultMethodBtn_Callback, true);
            app.DefaultMethodBtn.Tag = 'DefaultMethodBtn';
            app.DefaultMethodBtn.FontSize = 14.6666666666667;
            app.DefaultMethodBtn.Position = [97 621 88 25];
            app.DefaultMethodBtn.Text = 'Set Default';

            % Create OpenOptionsPanel
            app.OpenOptionsPanel = uibutton(app.qMRILab, 'push');
            app.OpenOptionsPanel.ButtonPushedFcn = createCallbackFcn(app, @OpenOptionsPanel_Callback, true);
            app.OpenOptionsPanel.Tag = 'OpenOptionsPanel';
            app.OpenOptionsPanel.FontSize = 13.3333333333332;
            app.OpenOptionsPanel.FontWeight = 'bold';
            app.OpenOptionsPanel.Position = [67 11 148 48];
            app.OpenOptionsPanel.Text = 'Open Options Panel';

            % Create MethodSelection
            app.MethodSelection = uidropdown(app.qMRILab);
            app.MethodSelection.Items = {'modelname'};
            app.MethodSelection.ValueChangedFcn = createCallbackFcn(app, @MethodSelection_Callback, true);
            app.MethodSelection.Tag = 'MethodSelection';
            app.MethodSelection.FontSize = 12.570970970971;
            app.MethodSelection.Position = [15 658 251 19];
            app.MethodSelection.ItemsData = 1;
            app.MethodSelection.Value = 1;

            % Create upgrade_message
            app.upgrade_message = uilabel(app.qMRILab);
            app.upgrade_message.Tag = 'upgrade_message';
            app.upgrade_message.HorizontalAlignment = 'center';
            app.upgrade_message.VerticalAlignment = 'top';
            app.upgrade_message.WordWrap = 'on';
            app.upgrade_message.FontSize = 14.6666666666667;
            app.upgrade_message.FontWeight = 'bold';
            qmrlab.gui.Theme.paint(app.upgrade_message, 'FontColor', 'accent');
            app.upgrade_message.Position = [7 701 268 22];
            app.upgrade_message.Text = 'Upgrade to v2.5.0';

            % Create Image
            app.Image = uiimage(app.qMRILab);
            app.Image.Tag = 'MainLogo';
            app.Image.Position = [27 746 228 78];
            % logo.png never existed in the repo -- only logo_light.png and logo_dark.png
            % do. applyTheme() replaces this on startup anyway; seed it with the light
            % asset so the component is valid before the theme is applied.
            app.Image.ImageSource = fullfile(pathToMLAPP, 'logo_light.png');

            % Re-home the fixed-position components into a responsive grid.
            applyResponsiveLayout(app);

            % Show the figure after all components are created
            app.qMRILab.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MainApp(varargin)

            % Reuse a live instance rather than stacking windows. The generated
            % form focused whatever getRunningApp returned; this validates the
            % handle first so a torn-down instance cannot poison the next launch.
            runningApp = getRunningApp(app);
            if ~isempty(runningApp) && isvalid(runningApp) && isvalid(runningApp.qMRILab)
                figure(runningApp.qMRILab)
                app = runningApp;
                if nargout == 0
                    clear app
                end
                return
            end

            createComponents(app)
            registerApp(app, app.qMRILab)
            runStartupFcn(app, @(app)qMRLab_OpeningFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.qMRILab)
        end
    end
end