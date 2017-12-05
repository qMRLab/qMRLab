function dataPath = downloadData(Model,path)
if ~exist('path','var') || isempty(path)
h = msgbox('Please select a destination to create example folder.','qMRLab');
waitfor(h);
path = uigetdir(); % Save batch example to this dir
end
cd(path);


mkdir([Model.ModelName '_demo']);
cd([Model.ModelName '_demo']);
if not(moxunit_util_platform_is_octave)
commandwindow;
end
disp('Please wait. Downloading data...');
try
    url = Model.onlineData_url;
catch
    warning(['No dataset for ' Model.ModelName])
    dataPath = [Model.ModelName '_data'];
    return
end
filename = [Model.ModelName '.zip'];
disp('before')
dir
try
    if moxunit_util_platform_is_octave
        [F, SUCCESS, MESSAGE] = urlwrite(url,filename);
        if ~SUCCESS, error(MESSAGE); end
    else
        websave(filename,url);
        disp('Data has been downloaded.');
    end
    
catch ME
    error(ME.identifier, ['Data cannot be downloaded: ' ME.message]);
end
disp('after')
dir
unzip(filename);



oldname = [path filesep [Model.ModelName '_demo'] filesep filename(1:end-4)];
if (exist(oldname,'dir')~=0)
    newname = [path filesep [Model.ModelName '_demo'] filesep filename(1:end-4) '_data'];
    movefile(oldname,newname);
    dataPath = newname;
else
    dirFiles = dir([path filesep Model.ModelName '_demo']);
    dirFiles=dirFiles(~ismember({dirFiles.name},{'.','..'}));
    mkdir([filename(1:end-4) '_data']);
    newname = [path filesep [Model.ModelName '_demo'] filesep filename(1:end-4) '_data'];
    for i =1:length(dirFiles)
        movefile(dirFiles(i).name,[newname filesep dirFiles(i).name]);
        dataPath = newname;
    end
end




end