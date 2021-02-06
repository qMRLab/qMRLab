function GenerateDocumentation(docDirectory)
%% Launch from any folder --> this script will create a folder qMRLab/Data
cd([fileparts(which('qMRLab.m')),'/src']);

mainDir = pwd; 

% Create a temporary folder on machine 
tmpDir = tempname;
mkdir(tmpDir);

% Create a folder named tmp in qMRLab directory (gitignored) 
mkdir([mainDir filesep 'tmp']);
dlmwrite([mainDir filesep 'tmp' filesep 'tmpDocDir.txt'],tmpDir,'delimiter','');

%% Generate Batch examples and publish
% Navigate to the temporary (private) folder. 
cd(tmpDir);
setenv('ISCITEST','1')
setenv('ISDOC','1')

Modellist = list_models';
for iModel = 1:length(Modellist)
    eval(['Model = ' Modellist{iModel}]);
    qMRgenBatch(Model,pwd)
    publish([Modellist{iModel} '_batch.m'])
    cd ..
    close all
end
setenv('ISCITEST','')
setenv('ISDOC','')

% delete old batch
list = sct_tools_ls([docDirectory filesep 'source/*_batch.rst'],1,1);
if ~isempty(list)
    delete(list{:})
end

% create new ones

system(['python ' docDirectory filesep 'auto_TOC.py ' fileparts(which('qMRLab.m'))]); % Gabriel Berestegovoy. gabriel.berestovoy@polymtl.ca

%% Build
%system('make')

% Remove tmp folder 
rmdir([mainDir filesep 'tmp'],'s')
rmdir(tmpDir,'s')
end