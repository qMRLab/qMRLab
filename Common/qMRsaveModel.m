function qMRsaveModel(Model, filename)
% save qMR Model object 
%   qMRsaveModel(Model)                 open a dialog box to let user
%                                        choose filename
%   qMRsaveModel(Model, filename)
if nargin<2
[file,path] = uiputfile(['qMRLab_' class(Model) 'Obj.mat'],'Save file name');
filename = fullfile(path,file);
end

if filename
    version = qMRLabVer;
    save(filename,'Model','version')
end
