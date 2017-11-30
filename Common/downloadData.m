function dataPath = downloadData(Model)

h = msgbox('Please select a destination to create example folder.','qMRLab');
waitfor(h);
path = uigetdir(); % Save batch example to this dir
cd(path);


mkdir([Model.ModelName '_demo']);
cd([Model.ModelName '_demo']);
commandwindow;
disp('Please wait. Downloading data...');

url = Model.onlineData_url;
filename = [Model.ModelName '.zip'];
try
    if moxunit_util_platform_is_octave
        urlwrite(url,filename);
    else
        websave(filename,url);
        disp('Data has been downloaded.');
    end
    
catch
    error('Data cannot be downloaded.');
end

unzip(filename);

if isunix
    sep = '/';
else
    sep = '\';
end

oldname = [path sep [Model.ModelName '_demo'] sep filename(1:end-4)];
if (exist(oldname,'dir')~=0)
    newname = [path sep [Model.ModelName '_demo'] sep filename(1:end-4) '_data'];
    movefile(oldname,newname);
    dataPath = newname;
else
    dirFiles = dir([path sep Model.ModelName '_demo']);
    dirFiles=dirFiles(~ismember({dirFiles.name},{'.','..'}));
    mkdir([filename(1:end-4) '_data']);
    newname = [path sep [Model.ModelName '_demo'] sep filename(1:end-4) '_data'];
    for i =1:length(dirFiles)
        movefile(dirFiles(i).name,[newname sep dirFiles(i).name]);
        dataPath = newname;
    end
end




end