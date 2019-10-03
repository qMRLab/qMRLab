function imtool3D_BIDS(BidsFolder)
% Viewer for BIDS folders
%  imtool3D_BIDS                 Opens a file browser to select a BIDS directory
%  imtool3D_BIDS(BidsFolder)     Parse BidsFolder and open the viewer
%
% Tanguy DUVAL, INSERM, 2019
% See also imtool3D_nii, imtool3D_nii_3planes, bids.layout, bids.query, imtool3D

% Load default BIDS folder
if nargin==0 || isempty(BidsFolder)
    BidsFolder = uigetdir('Select a BIDS Folder');
    if isequal(BidsFolder,0), return; end
end

% PANELS
h = figure('Name',['imtool3D BIDS Viewer -- ' BidsFolder],'MenuBar','none');
ptool = uipanel(h);
ptool.Position = [0,0,1,.8];
plb = uipanel(h);
plb.Position = [0,.8,1 .2];
% VIEWER
tool = imtool3D_nii_3planes([],[],ptool);
% LISTBOX
tsub = uicontrol(plb,'Style','listbox','Units','normalized','Position',[0 0 0.25 1],'Max',30);
tses = uicontrol(plb,'Style','listbox','Units','normalized','Position',[0.25 0 0.25 1],'Max',30);
tmodality = uicontrol(plb,'Style','listbox','Units','normalized','Position',[0.5 0 0.25 1],'Max',30);
tsequence = uicontrol(plb,'Style','listbox','Units','normalized','Position',[0.75 0 0.25 1],'Max',30);
% PARSE BIDS
BIDS = bids.layout(BidsFolder);
% fill subject listbox
tsub.String = bids.query(BIDS,'subjects');
tsub.Callback = @(hobj,evnt) filterDatabase(BIDS,tsub,tses,tmodality,tsequence,'sub');
tses.Callback = @(hobj,evnt) filterDatabase(BIDS,tsub,tses,tmodality,tsequence,'ses');
tmodality.Callback = @(hobj,evnt) filterDatabase(BIDS,tsub,tses,tmodality,tsequence,'modality');
tsequence.Callback = @(hobj,evnt) filterDatabase(BIDS,tsub,tses,tmodality,tsequence,'sequence');

% fill other listbox
filterDatabase(BIDS,tsub,tses,tmodality,tsequence,'sub');

% Add view button
btn_view = uicontrol(plb,'Style','pushbutton','String','view','Units','normalized','Position',[0.9 0 0.1 .3],'BackgroundColor',[0, 0.65, 1]);
btn_view.Callback = @(hobj,evnt) viewCallback(tool, BIDS,tsub,tses,tmodality,tsequence);

function filterDatabase(BIDS,tsub,tses,tmodality,tsequence,listbox)
if strcmp(listbox,'sub')
    tses.String = bids.query(BIDS,'sessions','sub',tsub.String{tsub.Value(1)});
    tses.Value(tses.Value>length(tses.String)) = [];
end

if strcmp(listbox,'sub') || strcmp(listbox,'ses')
    tmodality.String = bids.query(BIDS,'modalities','sub',tsub.String(tsub.Value),'ses',tses.String(tses.Value));
    tmodality.Value(tmodality.Value>length(tmodality.String)) = [];
end

if isempty(tses.String(tses.Value)) % no sessions
    tsequence.String = bids.query(BIDS,'types','sub',tsub.String(tsub.Value),'modality',tmodality.String(tmodality.Value));
else
    tsequence.String = bids.query(BIDS,'types','sub',tsub.String(tsub.Value),'ses',tses.String(tses.Value),'modality',tmodality.String(tmodality.Value));
end
tsequence.Value(tsequence.Value>length(tsequence.String)) = [];

function viewCallback(tool, BIDS,tsub,tses,tmodality,tsequence)
ht = wait_msgbox;
if isempty(tses.String(tses.Value)) % no sessions
    dat = bids.query(BIDS,'data','sub',tsub.String(tsub.Value),'modality',tmodality.String(tmodality.Value),'type',tsequence.String(tsequence.Value));
else
    dat = bids.query(BIDS,'data','sub',tsub.String(tsub.Value),'ses',tses.String(tses.Value),'modality',tmodality.String(tmodality.Value),'type',tsequence.String(tsequence.Value));
end
[dat, hdr, list] = nii_load(dat);
for ii=1:length(tool)
    tool(ii).setImage(dat);
    tool(ii).setAspectRatio(hdr.pixdim(2:4));
    tool(ii).setlabel(list);
end
if ishandle(ht), delete(ht); end

function h = wait_msgbox
txt = 'Loading files. Please wait...';
h=figure('units','norm','position',[.5 .75 .2 .2],'menubar','none','numbertitle','off','resize','off','units','pixels');
ha=uicontrol('style','text','units','norm','position',[0 0 1 1],'horizontalalignment','center','string',txt,'units','pixels','parent',h);
hext=get(ha,'extent');
hext2=hext(end-1:end)+[60 60];
hpos=get(h,'position');
set(h,'position',[hpos(1)-hext2(1)/2,hpos(2)-hext2(2)/2,hext2(1),hext2(2)]);
set(ha,'position',[30 30 hext(end-1:end)]);
disp(char(txt));
drawnow;

