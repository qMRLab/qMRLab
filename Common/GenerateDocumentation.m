cd([fileparts(which('qMRLab.m'))])
rmdir('Data','s')
mkdir Data
cd Data
%% Generate Batch examples
Modellist = list_models';
for iModel = 1:1%length(Modellist)
    eval(['Model = ' Modellist{iModel}]);
    qMRgenBatch(Model,pwd)
    
    setenv('ISTRAVIS','1')
    publish([Modellist{iModel} '_batch.m'])
    
    cd ..
end


%%
cd([fileparts(which('qMRLab.m'))])
cd docs
% delete old batch
list = sct_tools_ls('source/*_batch.rst',1,1);
delete(list{:})

% create new ones
system('python auto_TOC.py')
system('make')