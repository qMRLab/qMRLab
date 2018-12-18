function tool = imtool3D_nii_3planes(filename,maskname)
if ~exist('maskname','var'), maskname=[]; end
[dat, hdr] = load_nii_datas(filename,0);
if ~isempty(maskname)
    mask = load_nii_datas(maskname,0);
else
    mask = [];
end
tool = imtool3D_3planes(dat,mask{1});
% set voxelsize
H = getHandles(tool(1));
set(H.Axes,'DataAspectRatio',hdr.dime.pixdim([2 3 4]))
H = getHandles(tool(2));
set(H.Axes,'DataAspectRatio',hdr.dime.pixdim([3 4 2]))
H = getHandles(tool(3));
set(H.Axes,'DataAspectRatio',hdr.dime.pixdim([2 4 3]))