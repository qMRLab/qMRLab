% This function generates a batch example script.
%
% Input: Model (qMRLab object)
% Template: genBatch.qmr
%
% Written by: Agah Karakuzu, 2017

function qMRgenBatch(Model)

% Main function

% Define jokers and get class info ====================== START


attrList   = properties(Model);

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

% Define jokers and get class info ====================== END



% Directory definition ====================== START

demoDir = downloadData(Model);
[sep,~] = getUserPath();
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
    commandTexts.dataCommands = data2CLI(Model,demoDir,sep);
    
    
else % Unlikely yet ..
    explainTexts.dataExplain = {'% This object does not need input data.'};
    commandTexts.dataCommands = {' '}; % Set empty
end



% Generate model specific commands ====================== END


% Replace jokers ====================== START

% Read template line by line into cell array
fid = fopen('genBatch.qmr');
allScript = textscan(fid,'%s','Delimiter','\n');
allScript = allScript{1}; % This is a cell aray that contains template


% Recursively update newScript.
% Indexed structure arrays can be generated to reduce this section into a
% loop.

newScript = replaceJoker(varNames.jokerModel,varNames.modelName,allScript,1); % Model Name

newScript = replaceJoker(varNames.jokerDemoDir,demoDir,newScript,1);

newScript = replaceJoker(explainTexts.jokerProt,explainTexts.protExplain,newScript,2); % Prot Exp

newScript = replaceJoker(commandTexts.jokerProt,commandTexts.protCommands,newScript,2); % Prot Code

newScript = replaceJoker(explainTexts.jokerData,explainTexts.dataExplain,newScript,2); % Data Exp

newScript = replaceJoker(commandTexts.jokerData,commandTexts.dataCommands,newScript,2); % Data Code

% Replace jokers ====================== END


% Save batch example to a desired directory ====================== START

writeName = [varNames.modelName '_batch.m'];
cd(demoDir);
cd ..

fileID = fopen(writeName,'w');
formatSpec = '%s\n';
[nrows,~] = size(newScript);
for row = 1:nrows
    fprintf(fileID,formatSpec,newScript{row,:});
end


% Save batch example to a desired directory ====================== END



end

function [explain] = cell2Explain(str,modelName,itemName)

explain = cell(length(str)+2,1);

fs1 = ['%% ' modelName ' object needs %d ' itemName ' to be assigned:\n \n'];
exp1 = sprintf(fs1,length(str));
explain(1) = {exp1};

for i = 1:length(str)
    explain(i+1) = {['% ' str{i}]};
end

explain(length(str)+2) = {'% --------------'};

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
                newCommand = [newCommand expln];
                newCommand = [newCommand cmmnd];
            else
                part = sprintf(cont,curStr.Mat(j,:));
                cmmnd = {[remParant(curStr.Format{j}) ' = [' part '];']};
                expln = [ '% ' curStr.Format{j} ' is a vector of ' '[' '1' 'X' num2str(max(szM)) ']' ];
                newCommand = [newCommand expln];
                newCommand = [newCommand cmmnd];
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
    newCommand = [newCommand '% -----------------------------------------'];
    
    
end


protCommands = newCommand;

end

function dataCommands = data2CLI(Model,demoDir,sep)

reqData = Model.MRIinputs; % This is a cell

% @MODIFY
% Please add more file types if neccesary.
% Here I assume that required files are either mat or nii.gz

fooMat = cellfun(@(x)[x '.mat'],reqData,'UniformOutput',false);
fooNii = cellfun(@(x)[x '.nii.gz'],reqData,'UniformOutput',false);


matFiles = dir2Cell(demoDir,'*.mat');
niiFiles = dir2Cell(demoDir,'*.nii.gz');

matCommand = getDataAssign(matFiles,fooMat,reqData,'mat',demoDir,sep);
niiCommand = getDataAssign(niiFiles,fooNii,reqData,'nifti',demoDir,sep);

dataCommands = juxtaposeCommands(niiCommand,matCommand);


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

function datCommand = getDataAssign(input,foo,req,format,dir,sep)

% Subfunction of dataCommands.

% input: List of files with format format.
% foo: Pseudo array of MRIinputs with the extension to be tested.
% req: Required file names (MRIinputs)
% format: This format will be tested
% dir: Operation directory
% sep: / or \ depending on OS.

[boolIdx,~] = ismember(input,foo);
flg = ismember(1,boolIdx);

if flg
    eq= [];
    eq2 = [];
    readList = input(boolIdx);
    n = 1;
    for i=1:length(readList);
        
        if strcmp(format,'nifti')
            curDat = double(load_nii_data([dir sep readList{i}]));
            eq{n} = ['% ' readList{i} ' contains ' '[' num2str(size(curDat)) '] data.'];
            rd = readList{i};
            eq{n+1} = ['data.' rd(1:end-7) '=' 'double(load_nii_data(' '''' dir sep readList{i} '''' '));'];
            n = n+2;
        elseif strcmp(format,'mat')
            load([dir sep readList{i}]);
            dt = readList{i};
            dt = dt(1:end-4);
            curDat = eval(dt);
            eq{n} = ['% ' readList{i} ' contains ' '[' num2str(size(curDat)) '] data.'];
            eq{n+1} = [ ' load(' '''' dir sep readList{i} '''' ');'];
            n = n+2;
            eq2{i} = [' data.' req{i} '= double(' req{i} ');'];
        end
        
        
    end
    
    if strcmp(format,'nifti')
        datCommand = eq;
    elseif strcmp(format,'mat')
        datCommand  = [eq eq2];
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

IndexC = strfind(inScript, {thisJoker});
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

function [sep,rootDir] = getUserPath()

% Return user-specific qMRLab directory path.

usrPath = path;
loc = strfind(usrPath,'qMRLab');
idx = loc(2);
curStr = [];

while ~strcmp(curStr,':');
    curStr = usrPath(idx);
    idx = idx - 1;
end

rootDir = usrPath(idx+2:loc(2)+5);

if isunix
    sep = '/';
else
    sep = '\';
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
