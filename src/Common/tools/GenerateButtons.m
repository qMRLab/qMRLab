function handle = GenerateButtons(opts,ParentPanel, maxSize, ncol)
% Generate Buttons in vertical arrangement based on a cell array
% handle = GenerateButtons(opts,ParentPanel,maxButtonSize)
% Example:
%   Sim_Single_Voxel_Curve_buttons = {'SNR',50,'Method',{'Analytical equation','Bloch sim'},'Reset Mz',false}
%   h = figure;
%   buttons_handle = GenerateButtons(Sim_Single_Voxel_Curve_buttons,h,.2)
%   opts = button_handle2opts(button_handle)
%
% See also: button_handle2opts
ncol=1;

N = length(opts)/2;
if isempty(opts), handle=struct(); return; end
[I,J]=ind2sub([ncol N],1:(2*N)); Iw = 0.8/max(I); I=(0.1+0.8*(I-1)/max(I));
Jh = min(maxSize,1/(N+1)); J=1-Jh:-Jh:0; Jh=1.5*Jh;
for i = 1:N
    val = opts{2*i};
    tag=genvarname_v2(opts{2*i-1});
    if islogical(opts{2*i})
        handle.(tag) = uicontrol('Style','checkbox','String',opts{2*i-1},'ToolTipString',opts{2*i-1},...
            'Parent',ParentPanel,'Units','normalized','Position',[I(i) J(i) Iw Jh/2],...
            'Value',val,'HorizontalAlignment','center');
    elseif isnumeric(opts{2*i}) && length(opts{2*i})==1
        uicontrol('Style','Text','String',[opts{2*i-1} ':'],'ToolTipString',opts{2*i-1},...
            'Parent',ParentPanel,'Units','normalized','HorizontalAlignment','left','Position',[I(i) J(i) Iw/2 Jh/2]);
        handle.(tag) = uicontrol('Style','edit',...
            'Parent',ParentPanel,'Units','normalized','Position',[(I(i)+Iw/2) J(i) Iw/2 Jh/2],'String',val,'Callback',@(x,y) check_numerical(x,y,val));
    elseif iscell(opts{2*i})
        uicontrol('Style','Text','String',[opts{2*i-1} ':'],'ToolTipString',opts{2*i-1},...
            'Parent',ParentPanel,'Units','normalized','HorizontalAlignment','left','Position',[I(i) J(i) Iw/3 Jh/2]);
        if iscell(val), val = 1; else val =  find(cell2mat(cellfun(@(x) strcmp(x,val),opts{2*i},'UniformOutput',0))); end % retrieve previous value
        handle.(tag) = uicontrol('Style','popupmenu',...
            'Parent',ParentPanel,'Units','normalized','Position',[(I(i)+Iw/3) J(i) 2.2*Iw/3 Jh/2],'String',opts{2*i},'Value',val);
    elseif isnumeric(opts{2*i}) && length(opts{2*i})>1
             handle.(tag) = uitable(ParentPanel,'Data',opts{2*i},'Units','normalized','Position',[I(i) J(i) Iw Jh/2]);
    elseif strcmp(opts{2*i},'pushbutton')         
            handle.(tag) = uicontrol('Style','togglebutton','String',opts{2*i-1},'ToolTipString',opts{2*i-1},...
            'Parent',ParentPanel,'Units','normalized','Position',[I(i) J(i) Iw Jh/2],...
            'HorizontalAlignment','center');
    end
end

function check_numerical(src,eventdata,val)
str=get(src,'String');
if isempty(str2num(str))
    set(src,'string',num2str(val));
    warndlg('Input must be numerical');
end