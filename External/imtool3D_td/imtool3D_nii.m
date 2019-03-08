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

if iscell(filename), filename = filename{1}; end
set(H.Tools.Save,'Callback',@(hObject,evnt)saveImagenii(tool, filename))

function saveImagenii(tool, fname)
if exist(fname,'file')
h = tool.getHandles;
S = get(h.Tools.SaveOptions,'String');
switch S{get(h.Tools.SaveOptions,'value')}
    case 'Mask'
        [FileName,PathName] = uiputfile({'*.nii.gz'},'Save Mask',fullfile(fileparts(fname),'Mask'));
        save_nii_v2(tool.getMask(1),fullfile(PathName,FileName),fname,8);
    otherwise
        tool.saveImage;
end
else
    tool.saveImage;
end



