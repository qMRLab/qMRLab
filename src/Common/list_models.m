function [MethodList, pathmodels,ModelDir] = list_models
% list models
ModelDir = [fileparts(which('qMRLab.m')) filesep 'src' filesep 'Models'];
[MethodList, pathmodels] = sct_tools_ls([ModelDir filesep '*.m'],0,0,2,1);
MethodList = MethodList(cellfun(@isempty,strfind(pathmodels,'UnderDevelopment')));
MethodList = MethodList(~strcmp(MethodList,'CustomExample'));
