function dataPath = downloadData(Model,path)
if ~exist('path','var') || isempty(path)
h = msgbox('Please select a destination to create example folder.','qMRLab');
waitfor(h);
path = uigetdir(); % Save batch example to this dir
end
if ~path, dataPath = []; return; end
cd(path);
path = '.'; % use relative path

mkdir([Model.ModelName '_demo']);
cd([Model.ModelName '_demo']);
% if not(moxunit_util_platform_is_octave)
% commandwindow; %% remove this line--> not compatible with GUI usage
% end
disp('Please wait. Downloading data ...');
try
    url = Model.onlineData_url;
catch
    warning(['No dataset for ' Model.ModelName])
    dataPath = [Model.ModelName '_data'];
    return
end
filename = [Model.ModelName '.zip'];

% retry 3 times
count = 0;
err_count = 0;
while count == err_count
    try
        % DOWNLOAD
        if moxunit_util_platform_is_octave
            if isunix && ~isempty(getenv('ISCITEST')) && str2double(getenv('ISCITEST')) % issue #113 --> no outputs on TRAVIS
                cmd = ['curl -L -o ' filename ' ' url];
                disp(cmd)
                [STATUS,MESSAGE] = unix(cmd);
                if STATUS, error(MESSAGE); end
            else
                [~, SUCCESS, MESSAGE] = urlwrite(url,filename);
                if ~SUCCESS, error(MESSAGE); end
            end
        else
            websave(filename,url);
            disp('Data has been downloaded ...');
        end
        
        % UNZIP
        unzip(filename);
        err_count=0;
    catch ME
        err_count = err_count + 1;
        if err_count>3
            error(ME.identifier, ['Data cannot be downloaded: ' ME.message]);
        end
    end
    count = count + 1;
end




oldname = [path filesep filename(1:end-4)];
if (exist(oldname,'dir')~=0)
    newname = [path filesep filename(1:end-4) '_data'];
    movefile(oldname,newname);
    dataPath = newname;
else
    dirFiles = dir(path);
    dirFiles=dirFiles(~ismember({dirFiles.name},{'.','..'}));
    dirFiles=dirFiles(~[dirFiles.isdir]);
    mkdir([filename(1:end-4) '_data']);
    newname = [path filesep filename(1:end-4) '_data'];
    for i =1:length(dirFiles)
        if not(strcmp(dirFiles(i).name,'FitResults'))
        movefile(dirFiles(i).name,[newname filesep dirFiles(i).name]);
        dataPath = newname;
        end
    end
end




end