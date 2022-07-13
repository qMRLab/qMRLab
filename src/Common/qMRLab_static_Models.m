function [MethodList, pathmodels] = qMRLab_static_Models
% Static listing of all Models in the qMRLab Model folder

% OLD CONVENTION
%pathmodels = {'Diffusion/' 'Diffusion/' 'Diffusion/' 'FieldMaps/' 'FieldMaps/' 'FieldMaps/' 'Magnetization_transfer/' 'Magnetization_transfer/' 'Magnetization_transfer/' 'Magnetization_transfer/' 'Magnetization_transfer/' 'Noise/' 'Noise/' 'Processing/' 'QSM/' 'T1_relaxometry/' 'T1_relaxometry/' 'T1_relaxometry/' 'T2_relaxometry/' 'T2_relaxometry/' 'UnderDevelopment/'};
%MethodList = {'charmed' 'dti' 'noddi' 'b0_dem' 'b1_dam' 'b1_afi' 'mt_ratio' 'mt_sat' 'qmt_bssfp' 'qmt_sirfse' 'qmt_spgr' 'denoising_mppca' 'noise_level' 'filter_map' 'qsm_sb' 'inversion_recovery' 'vfa_t1' 'mp2rage' 'mtv' 'mwf' 'mono_t2' 'CustomExample'};

MethodList = modelRegistry('get','modellist');
pathmodels = modelRegistry('get','pathonly');

%{
% Comprehensive, adapt this one for testing.
[~,idxc] = ismember('CustomExample',MethodList);
MethodList(idxc) = [];
pathmodels = cell(1,length(MethodList));

for ii=1:length(MethodList)
    tmp = modelRegistry('get',MethodList{ii});
    pathmodels{1,ii} = tmp.Registry.ModelPath;
end
%}