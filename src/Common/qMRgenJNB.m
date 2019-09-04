function qMRgenJNB(Model,path,downloadCell)

api = qMRgenBatch;    
protStr = Model.Prot; % Get model prot here
protFlag = isempty(protStr); %
attrList   = fieldnames(Model);

[tmp,codeCell,mdCell] = getTemplateNB('jnbTemplate.ipynb');

explainTexts = struct();
commandTexts = struct();
varNames = struct();
varNames.modelName = Model.ModelName;
simTexts = struct();
% Depending on the model, there might be multiple field (other than format)

if ~exist('downloadCell','var') || ~downloadCell
    
    if ~exist('path','var')
        demoDir = downloadData(Model,[]);
    else
        demoDir = downloadData(Model,path);
    end
    
    down = [];

else
    
    if ~exist('path','var')
        demoDir = downloadData(Model,[]);
    else
        demoDir = downloadData(Model,path);
    end

    down.md = insert2Cell(mdCell,[{'## Download sample data from OSF'}, ...
    {['> The current `Model` is an instance of `' Model.ModelName '` class.']}, {' '} ...
    {['You can manually download the sample data for `' Model.ModelName '` [by clicking here](' Model.onlineData_url ').']}
    ]);
    down.code = insert2Cell(codeCell,{'dataDir = downloadData(Model,pwd);'});
end
if isempty(demoDir), return; end

sep = filesep;

descr.md = insert2Cell(mdCell,{'# I- DESCRIPTION'});
descr.code = insert2Cell(codeCell,{['qMRinfo(''' Model.ModelName '''); % Describe the model']});

model.md = insert2Cell(mdCell,[{'# II- MODEL PARAMETERS'},{'## a- Create object'}]);
model.code = insert2Cell(codeCell,{['Model = ' Model.ModelName ';']});

if ~protFlag % If prot is not emty
    
    explainTexts.protExplain = api.cell2Explain(fieldnames(protStr),varNames.modelName,'protocol field(s)');
    commandTexts.protCommands = api.prot2CLI(protStr);
    
    prot.md = insert2Cell(mdCell,[{'## b- Set protocol'},{'> Protocol is set according to the example data'},{' '}, ...
    explainTexts.protExplain']);
    prot.code = insert2Cell(codeCell,commandTexts.protCommands);

else % If prot is empty
    
    prot = [];

end

if ismember('MRIinputs',attrList)
    % Generate data explanation here
    explainTexts.dataExplain = api.cell2Explain(Model.MRIinputs,varNames.modelName,'data input(s)');
    % Generate data code here
    [type,commandTexts.dataCommands] = api.data2CLI(Model,demoDir,sep);
    
    data.md = insert2Cell(mdCell,[{'# III- FIT EXPERIMENTAL DATASET'},{'## a- Load experimental data'}, ...
    explainTexts.dataExplain']);
    data.code = insert2Cell(codeCell,commandTexts.dataCommands);
    
else % Unlikely yet ..
    explainTexts.dataExplain = {'% This object does not need input data.'};
    commandTexts.dataCommands = {' '}; % Set empty
end

    fit.md = insert2Cell(mdCell,[{'## b- Fit experimental data'},{'> This section will fit data.'}]);
    fit.code = insert2Cell(codeCell,{'FitResults = FitData(data,Model,0);'});

    show.md = insert2Cell(mdCell,[{'## c- Show fitting results'},{'> * Output map will be displayed.'},{' '}, ...
    {'> * If available, a graph will be displayed to show fitting in a voxel.'}]);
    show.code = insert2Cell(codeCell,{'qMRshowOutput(FitResults,data,Model);'});

 


if strcmp(type,'nii')
    
    saveCommand = ['FitResultsSave_nii(FitResults,' ' '''  Model.ModelName '_data' filesep Model.MRIinputs{1} '.nii.gz''' ');'];
    
elseif strcmp(type,'mat')

    saveCommand = 'FitResultsSave_nii(FitResults);';
end

    save.md = insert2Cell(mdCell,[{'## d- Save results'}, ...
    {'> * qMR maps are saved in NIFTI and in a structure `FitResults.mat` that can be loaded in qMRLab graphical user interface.'}, ...
    {'> * Model object stores all the options and protocol'}, ...
    {'> * These objects can be easily shared or be used for simulation.'}]);
    save.code = insert2Cell(codeCell, {saveCommand});

if Model.voxelwise && ~isempty(qMRusage(Model,'Sim_Single_Voxel_Curve'))
    svc = qMRusage(Model,'Sim_Single_Voxel_Curve');

    simTexts.SVCcommands = api.qMRUsage2CLI(svc);
    sa = qMRusage(Model,'Sim_Sensitivity_Analysis');
    simTexts.SAcommands = api.qMRUsage2CLI(sa);

    sim1.md = insert2Cell(mdCell,[{'# IV- SIMULATIONS'},{'> This section can be executed to run simulations for vfa_t1.'}, {' '}, ...
    {'## a- Single Voxel Curve'}, {'> Simulates single voxel curves:'},{' '}, {'       1. Use equation to generate synthetic MRI data'}, ...
    {'       2. Add rician noise'}, ...
    {'       3. Fit and plot curve'}]);

    sim1.code = insert2Cell(codeCell,simTexts.SVCcommands);

    sim2.md = insert2Cell(mdCell,[{'## b- Sensitivity analysis'}, {'> Simulates sensitivity to fitted parameters: '},{' '}, ...
    {'       1. Vary fitting parameters from lower (lb) to upper (ub) bound.'}, ...
    {'       2. Run Sim_Single_Voxel_Curve Nofruns times'}, ...
    {'       3. Compute mean and std across runs'}]);

    sim2.code = insert2Cell(codeCell,simTexts.SAcommands);

else
    sim1 = [];
    sim2 = [];
    simTexts.SVCcommands = {'% Not available for the current model.'};
    simTexts.SAcommands = {'% Not available for the current model.'};
end

cells = juxtaposeCells(descr,model,down,prot,data,fit,show,save,sim1,sim2);
tmp.cells = cells';

savejson('',tmp,'FileName',[Model.ModelName '_notebook.ipynb'],'ParseLogical',1);

% Small workaround
allScript = api.getTemplateFile([Model.ModelName '_notebook.ipynb']);
index = cellfun(@(x) strcmp(x,'"metadata": null,'), allScript, 'UniformOutput', 1);
allScript(index) = {'"metadata": {},'};

writeName = [Model.ModelName '_notebook.ipynb'];

fileID = fopen(writeName,'w');
formatSpec = '%s\n';
[nrows,~] = size(allScript);
for row = 1:nrows
    fprintf(fileID,formatSpec,allScript{row,:});
end
fclose(fileID);

curDir = pwd;
disp('------------------------------');
disp(['SAVED: ' Model.ModelName '_notebook.ipynb']);
disp(['Jupyter Notebook is ready at: ' curDir]);
disp('------------------------------');

end

function [tmp,codeCell,mdCell] = getTemplateNB(fileName)
    
    tmp = loadjson(fileName);
    cells = tmp.cells;

    % In the template, the first cell is a code cell 
    codeCell = cells(1);
    % The second cell is a markdown cell
    mdCell = cells(2);
    
    % These are enough to be used as building blocks. 
    
    tmp.cells = [];
end

function out = insert2Cell(codeCell,cellLine)

    codeCell{:}.source = lines2source(cellLine);
    out = codeCell;
end

function source = lines2source(lines)
% Here, lines is a cell array to be inserted in the ipynb 

source = cell(1,length(lines));
for ii = 1:length(lines)
    source{ii} = sprintf('%s\n',lines{ii});
    if ii == length(lines)
    source{ii} = sprintf('%s',lines{ii});
    end
end

end

function cells = juxtaposeCells(descr,model,down,prot,data,fit,show,save,sim1,sim2)

    cells = [];
    cells = [cells;descr.md;descr.code];
    cells = [cells;model.md;model.code];
    if ~isempty(down)
        cells = [cells;down.md;down.code];
    end
    if ~isempty(prot)
        cells = [cells;prot.md;prot.code];
    end
    cells = [cells;data.md;data.code];
    cells = [cells;fit.md;fit.code];
    cells = [cells;show.md;show.code];
    cells = [cells;save.md;save.code];
    if ~isempty(sim1)
        cells = [cells;sim1.md;sim1.code];
        cells = [cells;sim2.md;sim2.code];
    end

end