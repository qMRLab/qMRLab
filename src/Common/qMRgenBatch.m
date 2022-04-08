% This function generates a batch example script. based on template: genBatch.qmr
% qMRgenBatch(Model,path)
%   
% Input
%   Model        [qMRLab object]
%  (path)        [String]
%  (nodwnld)     [logical] download example dataset? 1 --> generate batch only
%
% Example
%  qMRgenBatch(inversion_recovery)
%op
% Written by: Agah Karakuzu, 2017

function api = qMRgenBatch(Model,path,nodwnld)
if nargin==0 && nargout==0, help qMRgenBatch, return; end

if nargin == 0

    % Open subfunctions of qMRgenBatch for outside access
    api.data2CLI = @data2CLI;
    api.cell2Explain = @cell2Explain;
    api.qMRUsage2CLI = @qMRUsage2CLI;
    api.prot2CLI = @prot2CLI;
    api.getDataAssign = @getDataAssign;
    api.dir2Cell = @dir2Cell;
    api.juxtaposeCommands = @juxtaposeCommands;
    api.getTemplateFile = @getTemplateFile;
    api.remParant = @remParant;
    api.replaceJoker = @replaceJoker;

else
% Main function

% Define jokers and get class info ====================== START

attrList   = fieldnames(Model);


explainTexts = struct();
explainTexts.jokerProt = '*-protExplain-*';
explainTexts.jokerData = '*-dataExplain-*';

commandTexts = struct();
commandTexts.jokerProt = '*-protCommand-*';
commandTexts.jokerData = '*-dataCommand-*';


varNames = struct();
varNames.jokerModel = '*-modelName-*';
varNames.jokerDemoDir = '*-demoDir-*';
varNames.modelName = class(Model);

simTexts = struct();
simTexts.jokerSVC = '*-SingleVoxelCurve-*';
simTexts.jokerSA = '*-SensitivityAnalysis-*';

noteTexts = struct();
noteTexts.jokerNote = '*-SpecificNotes-*';
noteTexts.jokerCite = '*-modelCitation-*';
notesJson = json2struct('docModelNotes.json');
notesGeneric = getGenericNotes(Model);
noteTexts.jokerNotesGeneric = '*-GenericNotes-*';

saveJoker = '*-saveCommand-*';

% Define jokers and get class info ====================== END



% Directory definition ====================== START
if ~exist('nodwnld','var') || ~nodwnld
    if ~exist('path','var')
        demoDir = downloadData(Model,[]);
    else
        demoDir = downloadData(Model,path);
    end
else
    demoDir = path;
end
if isempty(demoDir), return; end

sep = filesep;
% Directory definition ====================== END


% Generate model specific commands ====================== START

protStr = Model.Prot; % Get model prot here
protFlag = isempty(protStr); %

% Depending on the model, there might be multiple field (other than format)


if ~protFlag % If prot is not emty
    
    explainTexts.protExplain = cell2Explain(fieldnames(protStr),varNames.modelName,'protocol field(s)');
    
    commandTexts.protCommands = prot2CLI(protStr);
    
else % If prot is empty
    
    explainTexts.protExplain = {'% This object does not have protocol attributes.'};
    commandTexts.protCommands = {' '}; % Set empty
end

if ismember('MRIinputs',attrList)
    %F Generate data explanation here
    explainTexts.dataExplain = cell2Explain(Model.MRIinputs,varNames.modelName,'data input(s)');
    % Generate data code here
    [type,commandTexts.dataCommands] = data2CLI(Model,demoDir,sep);
    
    
else % Unlikely yet ..
    explainTexts.dataExplain = {'% This object does not need input data.'};
    commandTexts.dataCommands = {' '}; % Set empty
end

if ~isempty(str2double(getenv('ISDOC')))
    if str2double(getenv('ISDOC')) == 1
        ISDOC = true;
    else
        ISDOC = false;
    end
else
    ISDOC = false;
end

if strcmp(type,'nii')
    if ISDOC
        saveCommand = ['FitResultsSave_nii(FitResults_old,' ' '''  Model.ModelName '_data' filesep Model.MRIinputs{1} '.nii.gz''' ');'];
    else
        saveCommand = ['FitResultsSave_nii(FitResults,' ' '''  Model.ModelName '_data' filesep Model.MRIinputs{1} '.nii.gz''' ');'];
    end
elseif strcmp(type,'mat')
    if ISDOC
        saveCommand = 'FitResultsSave_mat(FitResults_old);';
    else
        saveCommand = 'FitResultsSave_mat(FitResults);';
    end
end

if ISDOC
    % Display red-colored box when no sim is available
    % TODO: Create a function that can return these formatted boxes with a custom text. 
    % A great intern task.
    notAvail = [{'% <html>'},...
    {'% <div class="danger" style="text-align:justify;">'},...
    {'% <p style="margin:0px!important;"><strong><i class="fa fa-info-circle" style="color:red;margin-left:5px;"></i></strong> Not available for the current model.</p>'},...
    {'% </div>'},...
    {'% </html>'}];
else
    notAvail = {'% Not available for the current model.'};
end

% MODEL SPECIFIC EXCEPTIONS FOR PROTOCOL CLI SECTION:
% In doc generation, send empty cell if no prot is available (protFlag==True)
% Do not create these fields in CI tests either (ISCITEST)
% * Or the model is amico 
% * Or the moodel is .... (please update when added new conditions)
if protFlag || strcmp(Model.ModelName,'amico')
    commandTexts.protCommands = notAvail; % Set empty
end

if ~isempty(getenv('ISCITEST')) % TEST ENV
    if str2double(getenv('ISCITEST'))==1
        commandTexts.protCommands = {'% Skipped in CI tests.'} ;
    end
end

% Inline substitution either way, so just define as a string.
noCitation = {'% _Reference article is not defined for this model._'};

if ISDOC
    % Display yellow-colored box when no sim is available
    noNotes = [{'% <html>'},...
    {'% <div class="warning" style="text-align:justify;">'},...
    {'% <p style="margin:0px!important;"><strong><i class="fa fa-info-circle" style="color:black;margin-left:5px;"></i></strong> Not provided.</p>'},...
    {'% </div>'},...
    {'% </html>'}];

else
    noNotes = {'% _No notes are available for this model._'};
    notesGeneric = {['% More information is available at https://qmrlab.readthedocs.io/en/master/' Model.ModelName '_batch.html']};
end

if Model.voxelwise && ~isempty(qMRusage(Model,'Sim_Single_Voxel_Curve'))
    svc = qMRusage(Model,'Sim_Single_Voxel_Curve');
    simTexts.SVCcommands = qMRUsage2CLI(svc);
    sa = qMRusage(Model,'Sim_Sensitivity_Analysis');
    simTexts.SAcommands = qMRUsage2CLI(sa);
else
    simTexts.SVCcommands = notAvail;
    simTexts.SAcommands = notAvail;
end

% Generate model specific commands ====================== END


for ii =1:length(notesJson.notes)
    
    if strcmp(Model.ModelName,notesJson.notes{ii}.model)
        if isfield(notesJson.notes{ii},'note')
            noteTexts.notes = cellstr(notesJson.notes{ii}.note');
        else
            noteTexts.notes = noNotes;
        end

        if isfield(notesJson.notes{ii},'citation')
            noteTexts.citation =cellstr(['% ' notesJson.notes{ii}.citation]);
        else
            noteTexts.citation = noCitation;
        end

        break;
    else
        noteTexts.notes = noNotes;
        noteTexts.citation = noCitation;
    end
    
end
% Replace jokers ====================== START

% Read template line by line into cell array
% Developer note: 
% Depending on the model, modifications to the standard template may be
% neccesary. If other model specific templates are needed for auto batch
% generation, please account for that here. To name this file:
%
% Please do not use underscores or any other special chars.
% foo_model --> genBatchfoomodel.qmr
doFinSubs = false;
if ~isempty(getenv('ISCITEST')) % TEST ENV

    if str2double(getenv('ISCITEST')) && (strcmp(varNames.modelName,'qsm_sb') || strcmp(varNames.modelName,'amico') || moxunit_util_platform_is_octave) % Octave and models avoiding assertion
        % There is an exceptional case for qsm_sb as it is not voxelwise 
        % and takes long to process.
        allScript = getTemplateFile('genBatchNoAssert.qmr');
    elseif ISDOC % Means documentation generation
        % During documentation generation, fit functions won't be called.
        allScript = getTemplateFile('genBatchDoc.qmr'); 
        doFinSubs = true;
    elseif str2double(getenv('ISCITEST')) && ~(strcmp(varNames.modelName,'qsm_sb') || strcmp(varNames.modelName,'amico')) % Means MATLAB CU
        % If not DOC, but MATLAB CI, run assertion to all but qsm and amico
        allScript = getTemplateFile('genBatchTestAssert.qmr');
    end    

else % USER whole datasets
   allScript = getTemplateFile('genBatchUser.qmr');
end

% Recursively update newScript.
% Indexed structure arrays can be generated to reduce this section into a
% loop.

newScript = replaceJoker(varNames.jokerModel,varNames.modelName,allScript,1); % Model Name

newScript = replaceJoker(varNames.jokerDemoDir,demoDir,newScript,1);

newScript = replaceJoker(saveJoker,saveCommand,newScript,1);

newScript = replaceJoker(explainTexts.jokerProt, commandTexts.protCommands, newScript,2);

newScript = replaceJoker(explainTexts.jokerData,explainTexts.dataExplain,newScript,2); % Data Exp

newScript = replaceJoker(commandTexts.jokerData,commandTexts.dataCommands,newScript,2); % Data Code

newScript = replaceJoker(simTexts.jokerSVC,simTexts.SVCcommands,newScript,2); % Sim 1

newScript = replaceJoker(simTexts.jokerSA,simTexts.SAcommands,newScript,2); % Sim 2

newScript = replaceJoker(noteTexts.jokerNote,noteTexts.notes,newScript,2);

newScript = replaceJoker(noteTexts.jokerNotesGeneric,notesGeneric,newScript,2); % Generic notes

newScript = replaceJoker(noteTexts.jokerCite,noteTexts.citation,newScript,2); % Model specific notes

if doFinSubs
    % Substitute model name jokers once again
    newScript = replaceJoker(varNames.jokerModel,varNames.modelName,newScript,1);
end    

% Replace jokers ====================== END


% Save batch example to a desired directory ====================== START

writeName = [varNames.modelName '_batch.m'];


fileID = fopen(writeName,'w');
formatSpec = '%s\n';
[nrows,~] = size(newScript);
for row = 1:nrows
    fprintf(fileID,formatSpec,newScript{row,:});
end
fclose(fileID);

% Save batch example to a desired directory ====================== END

curDir = pwd;
disp('------------------------------');
disp(['SAVED: ' writeName]);
disp(['Demo is ready at: ' curDir]);
disp('------------------------------');

end
end

function [explain] = cell2Explain(str,modelName,itemName)

explain = cell(length(str)+1,1);

fs1 = ['%%          |- ' modelName ' object needs %d ' itemName ' to be assigned:'];
exp1 = sprintf(fs1,length(str));
explain(1) = {exp1};

for i = 1:length(str)
    explain(i+1) = {['%          |-   ' str{i}]};
end

end

function protCommands = prot2CLI(protStr)

fNames = fieldnames(protStr); % These are the structs with Mat and Format

newCommand = {};
for i=1:length(fNames)
    
    curStr = getfield(protStr,fNames{i});
    
    % Double check if Mat and Format is there
    curStrfNames = fieldnames(curStr);
    flag = ismember(curStrfNames,{'Mat','Format'});
    if not(and(flag(1),flag(2)))
        error('Mat or Format is missing'); % Must be terminated otherwise
    end
    
    
    szM = size(curStr.Mat);
    len = length(curStr.Mat);
    idx = find(max(szM));
    
    if min(szM) == 1 && (length(curStr.Mat) == length(curStr.Format))
        
        
        if not(iscell(curStr.Format))
            curStr.Format = {curStr.Format};
        end
        
        for j = 1:length(curStr.Format)
            
            
            
            cmmnd = {[remParant(curStr.Format{j}) ' = ' num2str(curStr.Mat(j)) ';']}  ;
            newCommand = [newCommand cmmnd];
            
        end
        
    else
        
        if not(iscell(curStr.Format))
            curStr.Format = {curStr.Format};
        end
        
   
        
        for j = 1:length(curStr.Format)
            cont = repmat('%.4f; ',[1 len-1]);
            cont = [cont '%.4f'];
            if idx == 1
                part = sprintf(cont,curStr.Mat(:,j));
                cmmnd = {[remParant(curStr.Format{j}) ' = [' part '];']};
                expln = [ '% ' curStr.Format{j} ' is a vector of ' '[' num2str(max(szM)) 'X' '1' ']' ];
                newCommand = [newCommand cmmnd];
                newCommand = [newCommand expln];
            else
                part = sprintf(cont,curStr.Mat(j,:));
                cmmnd = {[remParant(curStr.Format{j}) ' = [' part '];']};
                expln = [ '% ' curStr.Format{j} ' is a vector of ' '[' '1' 'X' num2str(max(szM)) ']' ];
                newCommand = [newCommand cmmnd];
                newCommand = [newCommand expln];
            end
            
            
        end
        
        
    end
      
        
        % Assign vector with/without transpose.
        frm = [];
        for j =1:length(curStr.Format);
            frm = [frm ' ' remParant(curStr.Format{j})];
        end
        
        assgn=['Model.Prot.' fNames{i} '.Mat' ' = [' frm '];'];
        

    
    newCommand = [newCommand assgn];
    newCommand = [newCommand '%%   '];
    
    
end


protCommands = newCommand;



end

function [type,dataCommands] = data2CLI(Model,demoDir,sep)

reqData = Model.MRIinputs; % This is a cell

% @MODIFY
% Please add more file types if necessary.
% Here I assume that required files are either mat or nii.gz

fooMat = cellfun(@(x)[x '.mat'],reqData,'UniformOutput',false);
fooNii = cellfun(@(x)[x '.nii.gz'],reqData,'UniformOutput',false);


matFiles = dir2Cell(demoDir,'*.mat');
niiFiles = dir2Cell(demoDir,'*.nii.gz');

if not(isempty(matFiles))
    newMatFiles = cell(length(matFiles),1);
    
    for k = 1:length(Model.MRIinputs)
     curIdx = strmatch(Model.MRIinputs{k},matFiles);
     if not(isempty(curIdx))
         newMatFiles(k) = matFiles(curIdx);
     end
     
    end
    matFiles = newMatFiles;
    matFiles = matFiles(~cellfun('isempty',matFiles));
elseif not(isempty(niiFiles))
    
    newNiiFiles = cell(length(niiFiles),1);
    
    for k = 1:length(Model.MRIinputs)
     curIdx = strmatch(Model.MRIinputs{k},niiFiles);
     if not(isempty(curIdx))
         newNiiFiles(k) = niiFiles(curIdx);
     end
     
    end
    
    niiFiles = newNiiFiles;
    niiFiles = niiFiles(~cellfun('isempty',niiFiles));
end

matCommand = getDataAssign(matFiles,fooMat,reqData,'mat',demoDir,Model);
niiCommand = getDataAssign(niiFiles,fooNii,reqData,'nifti',demoDir,Model);



dataCommands = juxtaposeCommands(niiCommand,matCommand);

if ismember({' '},matCommand)
type = 'nii';
else
type = 'mat';
end

% To make operations free from dynamic navigation, commands will address
% directories.

end

function dirFiles = dir2Cell(anyDir,format)

% Get the list of all files in a specific format in anyDir.
% Output will be a cell array.

str = dir( fullfile(anyDir,format));
dirFiles = cell(1,length(str));
for i=1:length(str)
    dirFiles{i} = getfield(str,{i,1},'name');
end

end

function datCommand = getDataAssign(input,foo,req,format,dir,Model)

% Subfunction of dataCommands.

% input: List of files with format format.
% foo: Pseudo array of MRIinputs with the extension to be tested.
% req: Required file names (MRIinputs)
% format: This format will be tested
% dir: Operation directory
% sep: / or \ depending on OS.

[boolIdx,~] = ismember(input,foo);

visDir = [Model.ModelName '_data'];
flg = ismember(1,boolIdx);

if flg
    eq= [];
    eq2 = [];
    readList = input(boolIdx);
    n = 1;
    for i=1:length(readList);
        
        if strcmp(format,'nifti')
            curDat = double(load_nii_data([dir filesep readList{i}]));
            eq{n} = ['% ' readList{i} ' contains ' '[' num2str(size(curDat)) '] data.'];
            rd = readList{i};
            eq{n+1} = ['data.' rd(1:end-7) '=' 'double(load_nii_data(' '''' visDir filesep readList{i} '''' '));'];
            n = n+2;
            
        elseif strcmp(format,'mat')
            load([dir filesep readList{i}]);
            dt = readList{i};
            dt = dt(1:end-4);
            curDat = eval(dt);
            eq{n} = ['% ' readList{i} ' contains ' '[' num2str(size(curDat)) '] data.'];
            eq{n+1} = [ ' load(' '''' visDir filesep readList{i} '''' ');'];
            n = n+2;
            if ~all(Model.get_MRIinputs_optional)
                eq2{i} = [' data.' req{i} '= double(' req{i} ');'];
            else
                eq2{i} = [' data.' dt '= double(' dt ');'];
            end
            
        end
        
        
    end
    
    if strcmp(format,'nifti')
        datCommand = eq;
    elseif strcmp(format,'mat')  
        if ~isempty(eq2)
        datCommand  = [eq eq2];
        else
        datCommand = eq;    
        end
    end
    
else
    
    datCommand = {' '};
    
end

end

function snowBall = juxtaposeCommands(varargin)

% input: Flexible. You can pass multiple cells to concantenete them.
% output: Concanteneted cell array.

k = +nargin;
snowBall = []; % Conditional
for i=1:k
    if ~isempty(varargin{i})
        snowBall = [snowBall varargin{i}];
    end
end

end

function newScript = replaceJoker(thisJoker,replaceWith,inScript,type)

% thisJoker: Joker definition *- joker_def_here -*
% replaceWith: Cell Aray or cell to be repaced with thisJoker
% inScript : Input script (thisJoker will be replaced in inSCript)
% type: 1 or 2: In-line replacements or block replacements

IndexC = strfind(inScript, char({thisJoker}));
idx = find(not(cellfun('isempty', IndexC)));

if type == 1 % In-line replacements
    
    for i=1:length(idx)
        
        inScript(idx(i)) = strrep(inScript(idx(i)),{thisJoker},{replaceWith});
        
    end
    
    newScript = inScript;
    
elseif type ==2 % Code blocks
    
    lenNew = length(replaceWith);
    newScript = cell(length(inScript)+lenNew-1,1);
    try
        newScript(idx:(idx+lenNew-1)) = replaceWith;
    catch
        newScript(idx:(idx+lenNew-1)) = replaceWith';
    end
    newScript(1:(idx-1)) = inScript(1:(idx-1));
    newScript((idx+lenNew):(length(inScript)+lenNew-1)) = inScript((idx+1):end);
    
    
else
    
    
    
    
end

end



function out = remParant(in)

loc = strfind(in,'(');

if not(isempty(loc))
    out= in(1:loc-1);
else
    out = in;
end

end

function Cnew = qMRUsage2CLI(inStr)
C = strsplit(inStr,'\n');
C = C';
Cnew = C(~cellfun(@isempty, C));
Cnew = Cnew(2:end);
end

function allScript = getTemplateFile(fileName)
    fid = fopen(fileName);
    allScript = textscan(fid,'%s','Delimiter','\n');
    fclose(fid);
    allScript = allScript{1}; % This is a cell aray that contains template

end

function notes  = getGenericNotes(Model)
    notesJsonGeneric = json2struct('docGenericNotes.json');
    fixedNotes = [];
    condNotes = [];
    for ii=1:length(notesJsonGeneric.notes)
    if strcmp(notesJsonGeneric.notes{ii}.type,'fixed')
        % Assumption there is only one fixed field.
        fixedNotes = cellstr(notesJsonGeneric.notes{ii}.note');
    elseif strcmp(notesJsonGeneric.notes{ii}.type,'conditional')
        
        if Model.voxelwise
            if notesJsonGeneric.notes{ii}.voxelwise
                condNotes = cellstr(notesJsonGeneric.notes{ii}.note');
            end
        else
            if ~notesJsonGeneric.notes{ii}.voxelwise
                condNotes = cellstr(notesJsonGeneric.notes{ii}.note');
            end
        end
    
    end
    end
    notes = [fixedNotes;condNotes];
end