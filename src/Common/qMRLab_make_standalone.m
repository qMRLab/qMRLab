% get model list
ModelDir = [fileparts(which('qMRLab')) filesep 'src' filesep 'Models'];
[MethodList, pathmodels] = sct_tools_ls([ModelDir filesep '*.m'],0,0,2,1);
pathmodels = cellfun(@(x) strrep(x,[ModelDir filesep],''), pathmodels,'UniformOutput',false);

% save to a file
fid = fopen(fullfile(fileparts(which('qMRLab')),'qMRLab_static_Models.m'),'wt');
fprintf(fid,'function [MethodList, pathmodels] = qMRLab_static_Models\n');
fprintf(fid,...
    '%% Static listing of all Models in the qMRLab Model folder\n');
fprintf(fid,'pathmodels = {%s};\n', ['''' strjoin(pathmodels,''' ''') '''']);
fprintf(fid,'MethodList = {%s};\n', ['''' strjoin(MethodList,''' ''') '''']);
fclose(fid);


mcc -o qMRLab -W main:qMRLab -T link:exe -d /Users/Tanguy/code/qMRLab/src/Common/compiler/qMRLab/for_testing -v /Users/Tanguy/code/qMRLab/qMRLab.m -a /Users/Tanguy/code/qMRLab/External -a /Users/Tanguy/code/qMRLab/src 
