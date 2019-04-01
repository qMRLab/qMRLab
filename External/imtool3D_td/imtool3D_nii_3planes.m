function tool = imtool3D_nii_3planes(filename,maskname,hdr)
if nargin==0
    [filename, path] = uigetfile({'*.nii;*.nii.gz','NIFTI Files (*.nii,*.nii.gz)'},'Select an image','MultiSelect', 'on'); 
    if isequal(filename,0), return; end
    filename = fullfile(path,filename); 
end
if nargin==3
    dat = filename;
    mask = maskname;
else
    if ~exist('maskname','var'), maskname=[]; end
    [dat, hdr, list] = load_nii_datas(filename,0);
    disp(list)
    if iscell(maskname), maskname = maskname{1}; end
    if ~isempty(maskname)
        mask = load_nii_datas(maskname,0); mask = mask{1};
    else
        mask = [];
    end
end
% Call imtool3D_3planes
tool = imtool3D_3planes(dat,mask);

% Name figure
[path,file,ext] = fileparts(hdr.file_name);
set(tool(1).getHandles.fig,'Name',['imtool3D: ' file,ext ' (reference space)']);
set(tool(1).getHandles.fig,'NumberTitle','off');

% set voxelsize
for ii=1:3
tool(ii).setAspectRatio(hdr.pixdim(2:4));
end

% add header to save/load Mask
H = tool(3).getHandles;
set(H.Tools.maskSave,'Callback',@(hObject,evnt)saveMask(tool(3),hObject,hdr))
set(H.Tools.maskLoad,'Callback',@(hObject,evnt)loadMask(tool(3),hObject,hdr))

% add load Image features
Pos = get(tool(1).getHandles.Tools.Save,'Position');
Pos(1) = Pos(1) + Pos(3)+5;
Loadbut           =   uicontrol(tool(1).getHandles.Panels.Tools,'Style','pushbutton','String','','Position',Pos);
[iptdir, MATLABdir] = ipticondir;
icon_load = makeToolbarIconFromPNG([MATLABdir '/file_open.png']);
set(Loadbut,'CData',icon_load);
fun=@(hObject,evnt) loadImage(hObject,tool,hdr,path);
set(Loadbut,'Callback',fun)
set(Loadbut,'TooltipString','Load Image')

% add LPI labels
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String','L','Position',[0 0.5 0.05 0.05],'Color',[1 1 1]);
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String','R','Position',[1-0.05 0.5 0.05 0.05],'Color',[1 1 1]);
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String','A','Position',[0.5 1-0.05 0.05 0.05],'Color',[1 1 1]);
annotation(tool(1).getHandles.Panels.Image,'textbox','EdgeColor','none','String','P','Position',[0.5 0 0.05 0.05],'Color',[1 1 1]);

annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','P','Position',[0 0.5 0.05 0.05],'Color',[1 1 1]);
annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','A','Position',[1-0.05 0.5 0.05 0.05],'Color',[1 1 1]);
annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','S','Position',[0.5 1-0.05 0.05 0.05],'Color',[1 1 1]);
annotation(tool(2).getHandles.Panels.Image,'textbox','EdgeColor','none','String','I','Position',[0.5 0 0.05 0.05],'Color',[1 1 1]);

annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','L','Position',[0 0.5 0.05 0.05],'Color',[1 1 1]);
annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','R','Position',[1-0.05 0.5 0.05 0.05],'Color',[1 1 1]);
annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','S','Position',[0.5 1-0.05 0.05 0.05],'Color',[1 1 1]);
annotation(tool(3).getHandles.Panels.Image,'textbox','EdgeColor','none','String','I','Position',[0.5 0 0.05 0.05],'Color',[1 1 1]);


function loadImage(hObject,tool,hdr,path)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

[FileName,PathName] = uigetfile('*.nii;*.nii.gz','Load NIFTI',path,'MultiSelect', 'on');
if isequal(FileName,0)
    return;
end
if iscell(FileName)
    dat = load_nii_datas([{hdr.original},fullfile(PathName,FileName)]);
else
    dat = load_nii_datas({hdr.original,fullfile(PathName,FileName)});
end

I = tool(1).getImage(1);
for ii=1:3
    tool(ii).setImage([I(:)',dat(:)'])
    tool(ii).setNvol(1+length(I));
end

function icon = makeToolbarIconFromPNG(filename)
% makeToolbarIconFromPNG  Creates an icon with transparent
%   background from a PNG image.

%   Copyright 2004 The MathWorks, Inc.  
%   $Revision: 1.1.8.1 $  $Date: 2004/08/10 01:50:31 $

  % Read image and alpha channel if there is one.
  [icon,map,alpha] = imread(filename);

  % If there's an alpha channel, the transparent values are 0.  For an RGB
  % image the transparent pixels are [0, 0, 0].  Otherwise the background is
  % cyan for indexed images.
  if (ndims(icon) == 3) % RGB

    idx = 0;
    if ~isempty(alpha)
      mask = alpha == idx;
    else
      mask = icon==idx; 
    end
    
  else % indexed
    
    % Look through the colormap for the background color.
    if isempty(map), idx=1; icon = im2double(repmat(icon, [1 1 3])); return; end
    for i=1:size(map,1)
      if all(map(i,:) == [0 1 1])
        idx = i;
        break;
      end
    end
    
    mask = icon==(idx-1); % Zero based.
    icon = ind2rgb(icon,map);
    
  end
  
  % Apply the mask.
  icon = im2double(icon);
  
  for p = 1:3
    
    tmp = icon(:,:,p);
    if ndims(mask)==3
        tmp(mask(:,:,p))=NaN;
    else
        tmp(mask) = NaN;
    end
    icon(:,:,p) = tmp;
    
  end
