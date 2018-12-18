function tool = imtool3D_nii(filename,viewplane,maskfname, parent, range)
% imtool3D_nii fmri.nii.gz
% imtool3D_nii fmri.nii.gz sagittal
% imtool3D_nii *fmri*.nii.gz
% imtool3D_nii({'fmri.nii.gz', 'T1.nii.gz'})
if ~exist('parent','var'), parent=[]; end
if ~exist('viewplane','var'), viewplane=[]; end
if isempty(viewplane), untouch = true; else, untouch = false; end
if ~exist('range','var'), range=[]; end

[dat, hdr] = load_nii_datas(filename,untouch);
dat = setviewplane(dat,viewplane);
if nargin>2 && ~isempty(maskfname)
    mask = load_nii_datas(maskfname,untouch);
    mask = setviewplane(mask,viewplane);
    tool = imtool3D(dat,[],parent,range,[],mask{1},[]);
else
    tool = imtool3D(dat,[],parent,range,[],[],[]);
end

% set voxelsize
H = getHandles(tool);
set(H.Axes,'DataAspectRatio',hdr.dime.pixdim(2:4))

view(H.Axes,-90,90)
