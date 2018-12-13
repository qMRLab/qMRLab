function tool = imtool3D_nii(filename,viewplane,maskfname, parent, range)
% imtool3D_nii fmri.nii.gz
% imtool3D_nii fmri.nii.gz sagittal
% imtool3D_nii *fmri*.nii.gz
% imtool3D_nii({'fmri.nii.gz', 'T1.nii.gz'})
if ~exist('parent','var'), parent=[]; end
if ~exist('viewplane','var'), viewplane=[]; end
if ~exist('range','var'), range=[]; end

[dat, hdr] = imtool3D_load_nii(filename,viewplane);
if nargin>2 && ~isempty(maskfname)
    mask = imtool3D_load_nii(maskfname,viewplane);
    tool = imtool3D(dat,[],parent,range,[],mask{1},[]);
else
    tool = imtool3D(dat,[],parent,range,[],[],[]);
end

% set voxelsize
H = getHandles(tool);
set(H.Axes,'DataAspectRatio',hdr.dime.pixdim(2:4))

view(H.Axes,-90,90)
