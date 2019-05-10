function qMRdeployJNB(workdir)
    
Modellist = list_models';

for iModel = 1:length(Modellist)

    disp('==============================');
    disp(['Creating notebook for ' Modellist{iModel}]);
    eval(['Model = ' Modellist{iModel}]);
    qMRgenJNB(Model,workdir,1);
    
end

disp('COMPLETE');

end