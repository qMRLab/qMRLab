% get model list
qMRdir = fileparts(which('qMRLab'));
ModelDir = [fileparts(which('qMRLab')) filesep 'src' filesep 'Models'];
[MethodList, pathmodels] = sct_tools_ls([ModelDir filesep '*.m'],0,0,2,1);
pathmodels = cellfun(@(x) strrep(x,[ModelDir filesep],''), pathmodels,'UniformOutput',false);

% save Method list to a file
fid = fopen(fullfile(fileparts(which('qMRLab')),'qMRLab_static_Models.m'),'wt');
fprintf(fid,'function [MethodList, pathmodels] = qMRLab_static_Models\n');
fprintf(fid,...
    '%% Static listing of all Models in the qMRLab Model folder\n');
fprintf(fid,'pathmodels = {%s};\n', ['''' strjoin(pathmodels,''' ''') '''']);
fprintf(fid,'MethodList = {%s};\n', ['''' strjoin(MethodList,''' ''') '''']);
fclose(fid);

% save help to a file
clear hh
for imodel = 1:length(MethodList)
    hh.(MethodList{imodel}) = help(MethodList{imodel});
end
save(fullfile(fileparts(which('qMRLab')),'docs','iqmr_gethelp.mat'),'-struct','hh');

deploytool(fullfile(qMRdir,'/src/Common/compiler/qMRLab.prj'))
% mkdir(fullfile(qMRdir,'/src/Common/compiler/qMRLab/for_testing'))
% mcc('-o', 'qMRLab', '-W', 'main:qMRLab', '-T', 'link:exe',...
%     '-d', fullfile(qMRdir,'/src/Common/compiler/qMRLab/for_testing'),...
%     '-v', fullfile(qMRdir, 'qMRLab.m'), '-a', fullfile(qMRdir, 'External'),...
%     '-a', fullfile(qMRdir, 'src')) 
