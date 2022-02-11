function GenerateDocumentation(docDirectory,varargin)
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

    % Do not show warns in doc pages
    warning('off','all');
    
    p = inputParser();
    validPath = @(x) exist(x,'dir');
    validCellArray = @(x) isvector(x) && iscell(x);
    addRequired(p,'docDirectory',validPath);
    addParameter(p, 'SysEnv',[],@ischar);
    addParameter(p, 'BuildOnly',[],validCellArray);
    addParameter(p, 'BuildExcept',[],validCellArray);

    
    parse(p,docDirectory,varargin{:});

    buildOnly = p.Results.BuildOnly;
    buildExcept = p.Results.BuildExcept;
    sysEnvPATH = p.Results.SysEnv;

    if isempty(buildOnly) && isempty(buildExcept)
        Modellist = list_models';
        % SKIP NEW DOC GENERATION FOR AMICO
        % If you need to re-gen doc for amico, please comment out following two lines
        % Similar changes are required in
        % - InsertBadge.m 
        [~,amicoloc] = ismember(['amico'],Modellist);
        Modellist(amicoloc) = [];
    end
    
    if ~isempty(buildOnly)
        Modellist = buildOnly;
    end

    if ~isempty(buildExcept)
        Modellist = list_models';
        % SKIP NEW DOC GENERATION FOR AMICO
        % If you need to re-gen doc for amico, please comment out the next line
        buildExcept = [buildExcept,'amico']
        [~,drop] = ismember(buildExcept,Modellist )
        Modellist(drop) = [];
    end

    for iModel = 1:length(Modellist)
        eval(['Model = ' Modellist{iModel}]);
        qMRgenBatch(Model,pwd)
        publish([Modellist{iModel} '_batch.m'])
        cd ..
        close all
    end
    setenv('ISDOC','');
    setenv('ISCITEST','');
    % Enable warnings
    warning('on','all');

    % Only remove those are going to be re-generated, do not touch others.
    list = cellfun(@(x) [docDirectory filesep 'source' filesep x '_batch.rst'],Modellist,'UniformOutput',false);

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
    % GenerateDocumentation('~/Desktop/neuropoly/documentation','BuildOnly',{'inversion_recovery'});
    % env = 'Users/agah/opt/anaconda3/bin:/Users/agah/opt/anaconda3/condabin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'
    % GenerateDocumentation('~/Desktop/neuropoly/documentation','SysEnv',env,'BuildOnly',{'inversion_recovery'});
    
    if ~isempty(sysEnvPATH)
        setenv('PATH',sysEnvPATH);
    end
    % Plots python version to ensure that the right version is used.
    system(['python3 --version; python3 auto_TOC.py ' fileparts(which('qMRLab.m'))]); % Gabriel Berestegovoy. gabriel.berestovoy@polymtl.ca
    
    % Insert Binder badges to the rst files in the source dir
    insertBadge([docDirectory filesep 'source'],Modellist);
    %% Build
    % See requirements.txt in the docsDir
    % Same applies regarding the PATH
    % system('make') % RTD provides build from sources as service. Use only for local builds. 
    
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