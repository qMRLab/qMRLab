function tool = imtool3D_nii_3planes(filename,maskname)
if nargin==0
    [filename, path] = uigetfile({'*.nii;*.nii.gz','NIFTI Files (*.nii,*.nii.gz)'},'Select an image','MultiSelect', 'on'); 
    if isequal(filename,0), return; end
    filename = fullfile(path,filename); 
end
if ~exist('maskname','var'), maskname=[]; end
[dat, hdr, list] = load_nii_datas(filename,0);
disp(list)
if iscell(maskname), maskname = maskname{1}; end
if ~isempty(maskname)
    mask = load_nii_datas(maskname,0); mask = mask{1};
else
    mask = [];
end
% Call imtool3D_3planes
tool = imtool3D_3planes(dat,mask);

% Name figure
[path,file,ext] = fileparts(list{1});
set(tool(1).getHandles.fig,'Name',['imtool3D: ' file,ext ' (reference space)']);
set(tool(1).getHandles.fig,'NumberTitle','off');

% set voxelsize
for ii=1:3
tool(ii).setAspectRatio(hdr.pixdim(2:4));
end
% save Mask
H = tool(1).getHandles;
set(H.Tools.Save,'Callback',@(hObject,evnt)saveMask(tool(1),hdr))

% add load Mask and Image features
Pos = get(tool(1).getHandles.Tools.Save,'Position');
Pos(1) = Pos(1) + Pos(3)+5;
Loadbut           =   uicontrol(tool(1).getHandles.Panels.Tools,'Style','pushbutton','String','','Position',Pos);
[iptdir, MATLABdir] = ipticondir;
icon_load = makeToolbarIconFromPNG([MATLABdir '/file_open.png']);
set(Loadbut,'CData',icon_load);
fun=@(hObject,evnt) loadImage(hObject,tool,hdr,path);
set(Loadbut,'Callback',fun)
set(Loadbut,'TooltipString','Load NIFTI (Mask or Image)')


function saveMask(tool,hdr)
H = tool.getHandles;
S = get(H.Tools.SaveOptions,'String');
switch S{get(H.Tools.SaveOptions,'value')}
    case 'Mask'
        Mask = tool.getMask(1);
        if any(Mask(:))        
        [FileName,PathName, ext] = uiputfile({'*.nii.gz';'*.mat'},'Save Mask','Mask');
        FileName = strrep(FileName,'.gz','.nii.gz');
        FileName = strrep(FileName,'.nii.nii','.nii');
        if ext==1 % .nii.gz
            masknii.img = unxform_nii(hdr,Mask);
            masknii.hdr = hdr.original;
            nii_tool('save',masknii,fullfile(PathName,FileName))
        elseif ext==2 % .mat
            Mask = tool.getMask(1);
            save(fullfile(PathName,FileName),'Mask');
        end

        else
            warndlg('Mask empty... Draw a mask using the brush tools on the right')
        end
    otherwise
        tool.saveImage;
end

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
H = tool.getHandles;
S = get(H.Tools.SaveOptions,'String');
switch S{get(H.Tools.SaveOptions,'value')}
    case 'Mask'
        for ii=1:3
            tool(ii).setMask(uint8(dat{1}))
        end
    case 'Image'
        I = tool(1).getImage(1);
        for ii=1:3
            tool(ii).setImage([I(:)',dat(:)'])
            tool(ii).setNvol(length(dat)+size(I,5));
        end
end

function outblock = unxform_nii(hdr, inblock)

if isempty(hdr.rot_orient)
    outblock=inblock;
else
    [~, unrotate_orient] = sort(hdr.rot_orient);
    outblock = permute(inblock, [unrotate_orient 4 5 6 7]);
end

if ~isempty(hdr.flip_orient)
    flip_orient = hdr.flip_orient(unrotate_orient);
    
    for i = 1:3
        if flip_orient(i)
            outblock = flip(outblock, i);
        end
    end
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
