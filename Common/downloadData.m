function dataPath = downloadData(Model)

h = msgbox('Please select a destination to create example folder.','qMRLab');
waitfor(h);
path = uigetdir(); % Save batch example to this dir
cd(path);

ModelName = class(Model); % Update this with ModelName later.

mkdir([ModelName '_demo']);
cd([ModelName '_demo']);
commandwindow;
disp('Please wait. Downloading data...');

url = Model.onlineData_url;
filename = Model.onlineData_filename;
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

unzip(Model.onlineData_filename);

if isunix
    sep = '/';
else
    sep = '\';
end

oldname = [path sep [ModelName '_demo'] sep filename(1:end-4)];
newname = [path sep [ModelName '_demo'] sep filename(1:end-4) '_data'];
movefile(oldname,newname);

dataPath = newname;


end