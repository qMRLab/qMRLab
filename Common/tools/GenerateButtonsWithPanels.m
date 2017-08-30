function handles = GenerateButtonsWithPanels(buttons,ParentHandle)
%
%   Function that generate buttons with and without Panel
%   in a specific handle (ParentHandle)
% ----------------------------------------------------------------------------------------------------
%   Written by: Ian Gagnon, 2017
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
%   * Panel: If you want to regroup options in a panel, you must declare
%            the panel before:
%            1) Write 'PANEL'
%            2) Give his title
%            3) Give the number of options present in this panel
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
% buttons = {'NoPanel1',true,'PANEL','Panel1Title',4,'number1',1,'number2',2,'number3',3,'popupmenu1',{'choice1','choice2','choice3'},'NoPanel2',{1,2,3},'PANEL','Panel2Title',2,'number4',4,'checkbox2',false,};
% ParentHandle = 1;
% figure(1); h = GenerateButtonsWithPanels(buttons,1);

% Basics informations
PanelPos = find(strcmp(buttons,'PANEL')); % Panel position
nPanel = length(PanelPos);                % Number of panel
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
temp = diff([0, ~ismember(NumOpts,tempPanel), 0]); % Find options which are not in a panel
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
    
    Position = getpixelposition(ParentHandle);
    PanelHeight = 35/Position(4);
    PanelGap = 0.02;
% ----------------------------------------------------------------------------------------------------
    
    while io < nOpts
        
        % Fix the location and adjust the position (x,y,width and height)
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
        else 'WARNING';
        end
        yPrev = y;
        
        
        % Create Panels and fill them
        switch location 
            
            case 'Panel' % Reel Panels
                ReelPanel(ip) = uipanel('Parent',ParentHandle,'Title',PanelTitle{ip},'FontSize',11,'FontWeight','bold',...
                                        'BackgroundColor',[0.94 0.94 0.94],'Position',[x y Width Height]);
                htmp = GenerateButtonsInPanels(opts(io:NumPanel(2,ip)),ReelPanel(ip));
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
                htmp = GenerateButtonsInPanels(opts(io:NumNoPanel(2,inp)),FakePanel(inp));
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


function handle = GenerateButtonsInPanels(opts, PanelHandle, style)
if nargin < 3
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
         
for i = 1:N
    val = opts{2*i};
    tag = genvarname_v2(opts{2*i-1});
    if islogical(opts{2*i})
        handle.(tag) = uicontrol('Style','checkbox','String',opts{2*i-1},'ToolTipString',opts{2*i-1},...
            'Parent',PanelHandle,'Units','normalized','Position',[0.05 y(i) 0.9 Height],...
            'Value',val,'HorizontalAlignment','center');
    elseif isnumeric(opts{2*i}) && length(opts{2*i})==1
        uicontrol('Style','Text','String',[opts{2*i-1} ':'],'ToolTipString',opts{2*i-1},...
            'Parent',PanelHandle,'Units','normalized','HorizontalAlignment','left','Position',[0.05 y(i) Width Height]);
        handle.(tag) = uicontrol('Style','edit',...
            'Parent',PanelHandle,'Units','normalized','Position',[0.45 y(i) Width Height],'String',val,'Callback',@(x,y) check_numerical(x,y,val));
    elseif iscell(opts{2*i})
        uicontrol('Style','Text','String',[opts{2*i-1} ':'],'ToolTipString',opts{2*i-1},...
            'Parent',PanelHandle,'Units','normalized','HorizontalAlignment','left','Position',[0.05 y(i) Width Height]);
        if iscell(val), val = 1; else val =  find(cell2mat(cellfun(@(x) strcmp(x,val),opts{2*i},'UniformOutput',0))); end % retrieve previous value
        handle.(tag) = uicontrol('Style','popupmenu',...
            'Parent',PanelHandle,'Units','normalized','Position',[0.45 y(i) Width Height],'String',opts{2*i},'Value',val);
    elseif isnumeric(opts{2*i}) && length(opts{2*i})>1
             handle.(tag) = uitable(PanelHandle,'Data',opts{2*i},'Units','normalized','Position',[0.45 y(i) Width Height]);

    end
end

function check_numerical(src,eventdata,val)
str = get(src,'String');
if isempty(str2num(str))
    set(src,'string',num2str(val));
    warndlg('Input must be numerical');
end
