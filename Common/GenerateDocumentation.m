%% Launch from any folder --> this script will create a folder qMRLab/Data
cd([fileparts(which('qMRLab.m'))])
rmdir('Data','s')
mkdir Data
cd Data
%% Generate Batch examples and publish
setenv('ISTRAVIS','1')
Modellist = list_models';
for iModel = 1:length(Modellist)
    eval(['Model = ' Modellist{iModel}]);
    qMRgenBatch(Model,pwd)
    
    
    publish([Modellist{iModel} '_batch.m'])
    
    cd ..
end
setenv('ISTRAVIS','')

%% Generate restructured text files (docs/source/.rst)
cd([fileparts(which('qMRLab.m'))])
cd docs
% delete old batch
list = sct_tools_ls('source/*_batch.rst',1,1);
delete(list{:})

% create new ones
system('python auto_TOC.py'); % Gabriel Berestegovoy. gabriel.berestovoy@polymtl.ca

%% Build
system('make')