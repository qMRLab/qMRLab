function insertBadge(rstDir)



    Modellist = list_models';
    for iModel = 1:length(Modellist)
    
        disp('==============================');
        disp(['Inserting badge ' Modellist{iModel}]);
        
        api = qMRgenBatch;
        tmp = api.getTemplateFile([rstDir filesep Modellist{iModel} '_batch.rst']);
        nw = cell(length(tmp)+3,1);
        nw(1:2) = tmp(1:2);
        nw(4) = {'.. image:: https://mybinder.org/badge_logo.svg'};
        nw(5) = {[' :target: https://mybinder.org/v2/gh/qMRLab/doc_notebooks/master?filepath=' Modellist{iModel} '_demo.ipynb']};
        nw(7:end) = tmp(4:end);

        fileID = fopen([rstDir filesep Modellist{iModel} '_batch.rst'],'w');
        formatSpec = '%s\n';
        [nrows,~] = size(nw);
        for row = 1:nrows
            fprintf(fileID,formatSpec,nw{row,:});
        end
        fclose(fileID);

        
    end
    

end