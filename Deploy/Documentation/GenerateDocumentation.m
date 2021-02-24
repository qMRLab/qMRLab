function GenerateDocumentation(docDirectory,sysEnvPATH)
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
    % Set CITEST condition empty. During documentation generation, 
    % FIT won't happen. So, there's no point to enable testing conditions 
    % and dealing with partial datasets.
    % Example datasets requiring partial datasets are dealth with 
    % getLink abstract methods' third argument.
    
    setenv('ISCITEST','0'); 
    setenv('ISDOC','1');
    
    Modellist = list_models';
    for iModel = 1:length(Modellist)
        eval(['Model = ' Modellist{iModel}]);
        qMRgenBatch(Model,pwd)
        publish([Modellist{iModel} '_batch.m'])
        cd ..
        close all
    end
    setenv('ISDOC','');
    setenv('ISCITEST','');
    
    % delete old batch
    list = sct_tools_ls([docDirectory filesep 'source/*_batch.rst'],1,1);
    if ~isempty(list)
        delete(list{:})
    end
    
    % create new ones
    % This should be called from the docs directory.
    cd(docDirectory);
    % It is important to make this call from python3. MATLAB can give you
    % trouble while importing the libs.
    % If the python libs are imported from 2.7, then the documentation fails 
    % only for charmed and b1_dam (such a mystery :) ). But when you ensure
    % that the libs are imported from py3 then, it is OK. And no, in this
    % case <<python3 auto_TOC.py>> call won't work unless you properly set 
    % the environment with matlab.
    
    % If you run into the same problem, just sync PATH from your shell with
    % the PATH env var in MATLAB. In Unix, you can easily copy path to
    % clipboard by <<echo $PATH | pbcopy>> in terminal.
    % Then you can call this script like this: 
    % GenerateDocumentation('~/Desktop/neuropoly/documentation','Users/agah/opt/anaconda3/bin:/Users/agah/opt/anaconda3/condabin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin');
    
    if exist(sysEnvPATH,'var')
        setenv('PATH',sysEnvPATH);
    end
    % Plots python version to ensure that the right version is used.
    system(['python --version; python auto_TOC.py ' fileparts(which('qMRLab.m'))]); % Gabriel Berestegovoy. gabriel.berestovoy@polymtl.ca
    
    % Insert Binder badges to the rst files in the source dir
    insertBadge([docDirectory filesep 'source']);
    %% Build
    % See requirements.txt in the docsDir
    % Same applies regarding the PATH
    system('make')
    
    % Remove both tmp folders 
    rmdir([mainDir filesep 'tmp'],'s');
    rmdir(tmpDir,'s');
    disp(['Documentation sources are saved and built at: ' docDirectory]);
    gitInf = getGitInfo;
    gitInf.vertxt = qMRLabVer;
    savejson([],gitInf,[docDirectory filesep 'latestGitInfo.json']);
    disp('Information about current qMRLab branch and hash have been saved: latestGitInfo.json');
    cd(mainDir);
end