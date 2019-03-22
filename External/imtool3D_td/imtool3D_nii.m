function tool = imtool3D_nii(filename,viewplane,maskfname, parent, range)
% imtool3D_nii fmri.nii.gz
% imtool3D_nii fmri.nii.gz sagittal
% imtool3D_nii *fmri*.nii.gz
% imtool3D_nii({'fmri.nii.gz', 'T1.nii.gz'})
if ~exist('parent','var'), parent=[]; end
if ~exist('viewplane','var'), viewplane=[]; end
if isempty(viewplane), untouch = true; viewplane=3; else, untouch = false; end
if ~exist('range','var'), range=[]; end

[dat, hdr] = load_nii_datas(filename,untouch);
if nargin>2 && ~isempty(maskfname) && (~iscell(maskfname) || ~isempty(maskfname{1}))
    mask = load_nii_datas(maskfname,untouch);
    tool = imtool3D(dat,[],parent,range,[],mask{1},[]);
else
    tool = imtool3D(dat,[],parent,range,[],[],[]);
end

% set voxelsize
tool.setAspectRatio(hdr.pixdim(2:4));

% set viewplane
setviewplane(tool,viewplane);


H = getHandles(tool);
view(H.Axes,-90,90)

set(H.Tools.maskSave,'Callback',@(hObject,evnt)saveMask(tool,hObject,hdr))
set(H.Tools.maskLoad,'Callback',@(hObject,evnt)loadMask(tool,hObject,hdr))

