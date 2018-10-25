function handles = GenerateButtonsWithPanels(buttons,ParentHandle, tips)
%
%   Function that generate buttons with and without Panel
%   in a specific handle (ParentHandle)
% ----------------------------------------------------------------------------------------------------
%   Written by: Ian Gagnon, 2017
%   Modified  : Agah Karakuzu, 2018
% ----------------------------------------------------------------------------------------------------
%   INPUTS:
%   1) buttons: A big cell containing all the buttons you want to create.
%               ** you must use the given nomenclature! **
%   2) ParentHandle: The handle in which you want to create theses buttons.
% ----------------------------------------------------------------------------------------------------
%   OUTPUTS:
%   1) handles: handles to every uicontrol (one per option) created.
% ----------------------------------------------------------------------------------------------------
%   NOMENCLATURE:
%   * Global: Always put the title of the option as a string BEFORE the option
%             If the title starts with ### --> option is disabled
%   * Panel: If you want to regroup options in a panel, you must declare
%            the panel before:
%            1) Write 'PANEL'
%            2) Give his title
%            3) Give the number of options present in this_ panel
%     Example: buttons = {'PANEL','PanelTitle','nOptions',...}
%   * Number: Simply write the number after his title
%     Example: buttons = {'Option',1}
%   * Checkbox: Write a logical TRUE or FALSE
%     Example: buttons = {'Option',true}
%   * Popupmenu: Write a cell with all the popopmenu choices
%               ** Choices can be number, string or both **
%     Example1: buttons = {'Option',{'choice1','choice2','choice3'}}
%     Example2: buttons = {'Option',{1,2,3}}
% ----------------------------------------------------------------------------------------------------
%   COMPLETE EXAMPLE:
% buttons = {'NoPanel1',true,'PANEL','Panel1Title',4,'number1',1,'###number2',2,'number3',3,'popupmenu1',{'choice1','choice2','choice3'},'NoPanel2',{1,2,3},'PANEL','Panel2Title',2,'number4',4,'checkbox2',false,};
% ParentHandle = 1;
% figure(1); h = GenerateButtonsWithPanels(buttons,1);
% % Read buttons
% Options = button_handle2opts(h);
%
%
% See also button_handle2opts

% PANEL<paneID><NumberOfUIObjects>
%
% PANEL is a specific key value that indicates two preceding entries
% include descriptive values for a panel object to be created.
% The first one is the PanelID, the second one is the number of UIObjects
% that will be scoped by this panel.
%
% Arguments following the second value of the PANEL key are subjected
% to the button generation rules for checkboxes, popupmenus, single val
% inputs and tables. Total number of button generation key<value> pairs
% should equal to the number indicated by second value of the PANEL key.



PanelPos = find(strcmp(buttons,'PANEL')); % Panel position
nPanel = length(PanelPos);                % Number of panels
nOpts = (length(buttons)-3*nPanel);       % Number of options

% Panel declarations

PanelTitle = cell(1,nPanel);
PanelnElements = ones(1,nPanel);
PanelNum = ones(1,nPanel);

% Take the title and the number of element in memory before removing the
% Panel informations ('PANEL','PanelTitle','PanelnElements')

for i = 1:nPanel
    PanelNum(i) = PanelPos(i) - 3*(i-1);
    PanelTitle(i) = buttons(PanelNum(i)+1);
    PanelnElements(i) = buttons{PanelNum(i)+2};
    buttons([PanelNum(i),PanelNum(i)+1,PanelNum(i)+2]) = [];
end
opts = buttons;

% Each column of NumPanel and NumNoPanel indicates the beginning (row1) and
% the end (row2) of a group of options combine whether in the same panel
% (NumPanel) or between 2 panels (NumNoPanel)

NumOpts = 1:nOpts;
NumPanel = ones(2,nPanel);
tempPanel = [];

for iP = 1:nPanel
    NumPanel(:,iP) = [PanelNum(iP);PanelNum(iP)+2*PanelnElements(iP)-1];
    tempPanel = horzcat(tempPanel, NumPanel(1,iP):NumPanel(2,iP));
end

% Below line gives buttons that are not scoped by a panel.
temp = diff([0, ~ismember(NumOpts,tempPanel), 0]);

NumNoPanel = [find(temp==1); find(temp==-1)-1];

NoPanelnElements = (NumNoPanel(2,:)-NumNoPanel(1,:)+1)/2;


if ~isempty(opts)

    % Counters declaration
    io = 1; % Object
    ip = 1; % Panel
    inp = 1; % NoPanel
    yPrev = 1; % Starting point for the first Panel/NoPanel

% ----------------------------------------------------------------------------------------------------
%   PANELS DISPLAY
    if ~exist('ParentHandle','var'), ParentHandle = figure; end
    Position = getpixelposition(ParentHandle);
    PanelHeight = 35/Position(4);
    PanelGap = 0.02;
% ----------------------------------------------------------------------------------------------------

    while io < nOpts

        % Fix the location and adjust the position (x, y, width and height)

        if find(NumPanel(1,:)==io)

            location = 'Panel';
            x = 0.05;
            Width = 0.905;
            Height = PanelHeight*PanelnElements(ip);
            y = yPrev - PanelGap - Height;

        elseif find(NumNoPanel(1,:)==io)

            location = 'NoPanel';
            x = 0;
            Width = 1;
            Height = PanelHeight*NoPanelnElements(inp);
            y = yPrev - PanelGap - Height;

        else

        warning('WARNING');

        end

        yPrev = y;


        % Create Panels and fill them
        switch location

            case 'Panel' % Reel Panels

                if strcmp(PanelTitle{ip}(1:min(end,2)),'##')
                   disablepanel = true;
                 else
                   disablepanel=false;
                 end

                ReelPanel(ip) = uipanel('Parent',ParentHandle,'Title',PanelTitle{ip},'FontSize',11,'FontWeight','bold',...
                                        'BackgroundColor',[0.94 0.94 0.94],'Position',[x y Width Height]);

                if disablepanel, set(ReelPanel(ip),'Visible','off'); end


                htmp = GenerateButtonsInPanels(opts(io:NumPanel(2,ip)),ReelPanel(ip),[],tips);

                f = fieldnames(htmp);

                for i = 1:length(f)
                    handles.([genvarname_v2(PanelTitle{ip}) '_' f{i}]) = htmp.(f{i});
                end

                io = NumPanel(2,ip)+1;
                ip = ip+1;

            case 'NoPanel' % "Fake" Panels

                FakePanel(inp) = uipanel('Parent',ParentHandle,'BorderType','none','BackgroundColor',[0.94 0.94 0.94],...
                                         'Position',[x y Width Height]);

                npref = strcat('NoPanel',num2str(inp)); % NoPanel reference in the handle

                if not(exist('tips','var'))
                    tips = {};
                end
                
                htmp = GenerateButtonsInPanels(opts(io:NumNoPanel(2,inp)),FakePanel(inp),[],tips);

                f = fieldnames(htmp);

                for i = 1:length(f)

                    handles.(f{i}) = htmp.(f{i});

                end

                io = NumNoPanel(2,inp)+1;

                inp = inp+1;

            case 'WARNING'

                warndlg('Your "buttons" input isn''t good!','WRONG!');

        end
    end
end


function handle = GenerateButtonsInPanels(opts, PanelHandle, style, tips)

if nargin < 3 || isempty(style)

    style = 'SPREAD'; %Set 'SPREAD' display as default

end

N = length(opts)/2;

% ----------------------------------------------------------------------------------------------------
%   OPTIONS DISPLAY

    Height = 0.6/N;
    Width = 0.5;

    if N == 1 %Special condition if N=1
        y = (1-Height)/2;

    elseif N == 2

        y = N/(N+1)-Height/4:-1/(N+1)-Height/2:0; %Special condition if N=2

    else

        switch style

            case 'CENTERED'

                y = N/(N+1)-Height/2:-1/(N+1):0;

            case 'SPREAD'

                y = N/(N+1):-1/(N+1)-Height/(N-1):0;
        end
    end
% ----------------------------------------------------------------------------------------------------

% The below comments belong to the buttons that are not scoped by a Panel:
%
% When prepended to the button name (obj.buttons{idx}) ### disables the
% corresponding UIControl object on the Options panel.
%
% When prepended to the button name (obj.buttons{idx}) *** hides the
% corresponding UIControl object on the Options panel.

for ii = 1:N 

    % Buttons are ordered as key<value> pairs in an array form.

    % 2*ii is for value
    % 2*ii-1 is for key

    val = opts{2*ii};

    % special case: disable if ### in option name
    if strcmp(opts{2*ii-1}(1:2),'##')

       opts{2*ii-1} = opts{2*ii-1}(3:end);
       disable=true;

    else

       disable = false;

    end

    if strcmp(opts{2*ii-1}(1:2),'**')

       opts{2*ii-1} = opts{2*ii-1}(3:end);
       noVis = true;

    else

      noVis =false;

    end

    % Variable names are generated regarding the key. Since these elements
    % are not scoped by a panel, they will be accessed at the first level
    % of the obj.options field.

    % genvarname_v2 will get rid of several chars such as white spaces,
    % parantheses etc., but also the disable/hide Jokers.

    tag = genvarname_v2(opts{2*ii-1});

    % Below if-else conditions are to deduce which type of UIObject will
    % be placed at the Options panel, regarding the itered <value>.

    if islogical(opts{2*ii}) % Checkbox (true/false)
        
        % Checkbox itself  
        handle.(tag) = uicontrol('Style','checkbox','String',opts{2*ii-1},'ToolTipString',opts{2*ii-1},...
            'Parent',PanelHandle,'Units','normalized','Position',[0.05 y(ii) 0.9 Height],...
            'Value',logical(val),'HorizontalAlignment','center');

    elseif isnumeric(opts{2*ii}) && length(opts{2*ii})==1 % Single val i/p
        
        % Entry box label 
        handle.([tag 'lbl']) = uicontrol('Style','Text','String',[opts{2*ii-1} ':'],'ToolTipString',opts{2*ii-1},...
            'Parent',PanelHandle,'Units','normalized','HorizontalAlignment','left','Position',[0.05 y(ii) Width Height]);
        
        % Entry box itself  
        handle.(tag) = uicontrol('Style','edit',...
            'Parent',PanelHandle,'Units','normalized','Position',[0.45 y(ii) Width Height],'String',val,'Callback',@(x,y) check_numerical(x,y,val));

    elseif iscell(opts{2*ii}) % Pop-up (or dropdown...) menu.

        % popup menu label 
        handle.([tag 'lbl']) = uicontrol('Style','Text','String',[opts{2*ii-1} ':'],'ToolTipString',opts{2*ii-1},...
            'Parent',PanelHandle,'Units','normalized','HorizontalAlignment','left','Position',[0.05 y(ii) Width Height]);

        if iscell(val), val = 1; else val =  find(cell2mat(cellfun(@(x) strcmp(x,val),opts{2*ii},'UniformOutput',0))); end % retrieve previous value
        
        % popup menu itself 
        handle.(tag) = uicontrol('Style','popupmenu',...
            'Parent',PanelHandle,'Units','normalized','Position',[0.45 y(ii) Width Height],'String',opts{2*ii},'Value',val);



    elseif isnumeric(opts{2*ii}) && length(opts{2*ii})>1 % A table.
        
        % table label 
        handle.([tag 'lbl']) =  uicontrol('Style','Text','String',[opts{2*ii-1} ':'],'ToolTipString',opts{2*ii-1},...
            'Parent',PanelHandle,'Units','normalized','HorizontalAlignment','left','Position',[0.05 y(ii) Width Height]);
             
             % table itself 
             handle.(tag) = uitable(PanelHandle,'Data',opts{2*ii},'Units','normalized','Position',[0.45 y(ii) Width Height*1.1]);
             
             % table assingment options till the next elseif 
             set(handle.(tag),'ColumnEditable',true(1,size(opts{2*ii},2)));

             % Hardcoded convention to assign whether as Row or Col name

             if size(opts{2*ii},1)<5, set(handle.(tag),'RowName',''); end

             widthpx = getpixelposition(PanelHandle)*Width; widthpx = floor(widthpx(3))-2; % ?

             if size(opts{2*ii},2)<5, set(handle.(tag),'ColumnName',''); set(handle.(tag),'ColumnWidth',repmat({widthpx/size(opts{2*ii},2)},[1 size(opts{2*ii},2)])); end

    elseif strcmp(opts{2*ii},'pushbutton') % This creates a button.

             % Agah: Trace how to assign a callback to this.

             handle.(tag) = uicontrol('Style','togglebutton','String',opts{2*ii-1},'ToolTipString',opts{2*ii-1},...
            'Parent',PanelHandle,'Units','normalized','Position',[0.05 y(ii) 0.9 Height],...
            'HorizontalAlignment','center');
    end

    if disable % Please see the first if statement inside the loop line250.

        set(handle.(tag),'enable','off');

    end

    if noVis % Please see the second if statement inside the loop line250.

        set(handle.(tag),'visible','off');
        fnames = fieldnames(handle);
        boolLbl = ismember([tag 'lbl'],fnames);

        if boolLbl
            set(handle.([tag 'lbl']),'visible','off');
        end

    end

    % Below if statement is to add TooltipString to the OptionsPanel BUTTONS
    % For buttons accompanied by a label object, only label will attain the
    % tip string. Otherwise some objects (such as tables) are going to 
    % collapse, partially visible etc. 
    
    
    
    if not(isempty(tips)) % Add Tooltip string 
        
        % Convert all cell to the varnames including tip explanations
        tipTag = cellfun(@genvarname_v2, tips,'UniformOutput',false);
        
        % Odd entries contain the keys. Get tag vars only. 
        tipTag = tipTag(1:2:end);
        tipsy   = tips(2:2:end);
        [bool, pos] = ismember(tag,tipTag);
        if bool

            

            fnames = fieldnames(handle);
            boolLbl = ismember([tag 'lbl'],fnames);
            
            if boolLbl
                set(handle.([tag 'lbl']),'Tooltipstring',tipsy{pos});
            else
                set(handle.(tag),'Tooltipstring',tipsy{pos});
            end

        end

    end

end

function check_numerical(src,eventdata,val)

str = get(src,'String');

if isempty(str2num(str))

    set(src,'string',num2str(val));
    warndlg('Input must be numerical');

end
