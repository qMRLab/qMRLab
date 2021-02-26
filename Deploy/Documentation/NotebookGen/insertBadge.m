% Assumes that .. raw:: html is @ l3 
% Insert badge w.r.t. modelname 
% TODO: Explain. 

function insertBadge(rstDir)



    Modellist = list_models';
    for iModel = 1:length(Modellist)
    
        disp('==============================');
        disp(['Inserting badge ' Modellist{iModel}]);
        
        api = qMRgenBatch;
        tmp = api.getTemplateFile([rstDir filesep Modellist{iModel} '_batch.rst']);
        nw = cell(length(tmp)+2,1);
        nw(1:2) = tmp(1:2);
        % Skip line 3
        nw(4) = {'.. image:: https://mybinder.org/badge_logo.svg'};
        nw(5) = {[' :target: https://mybinder.org/v2/gh/qMRLab/doc_notebooks/master?filepath=' Modellist{iModel} '_notebook.ipynb']};
        nw(6:end) = tmp(4:end);
        
        % indent html block (omit tag)
        for ii=7:length(nw)
           nw(ii) = {sprintf('\t%s',nw{ii})}; 
        end
        
        
        fileID = fopen([rstDir filesep Modellist{iModel} '_batch.rst'],'w');
        formatSpec = '%s\n';
        [nrows,~] = size(nw);
        for row = 1:nrows
            fprintf(fileID,formatSpec,nw{row,:});
        end
        fclose(fileID);

        
    end
    

end