function Model = qMRloadModel(filename)
% load qMR Model object. Reads the version of the object and ensure
% compatibility.
%
%   qMRloadModel()                 open a dialog box to let user
%                                        choose filename
%   qMRloadModel(filename)
if nargin<1
[file,path] = uigetfile({'qMRLab_*Obj.mat;*.mat'},'Load file name');
filename = fullfile(path,file);
end

if filename
    load(filename,'Model','version')
    if ~exist('Model','var'), warning('not a Model object file');  Model = []; return; end
    if ~exist('version','var'), warning('No variable name "version". Might not be retrocompatible. Save Models using qMRsaveModel to prevent this error.');  return; end
    Model = qMRpatch(Model,version);
end
