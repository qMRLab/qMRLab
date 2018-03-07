function BatchExample_heavy(path)
curdir = path;
Modellist = list_models';
for iModel = 1:length(Modellist)
    if  not(strcmp(Modellist{iModel},'vfa_t1'))
    disp('===============================================================')
    disp(['Testing: ' Modellist{iModel} ' BATCH...'])
    disp('===============================================================')

    eval(['Model = ' Modellist{iModel}]);
    qMRgenBatch(Model,pwd)
    
    eval([Modellist{iModel} '_batch'])
    
    cd ..
    end
end
cd(curdir)
disp('COMPLETE');
end