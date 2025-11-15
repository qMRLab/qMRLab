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
            % Try multiple methods to handle OSF redirects (308 status)
            download_success = false;

            % Method 1: Try system curl (most reliable for redirects)
            if isunix || ismac
                try
                    cmd = ['curl -L -o ' filename ' "' url '"'];
                    [STATUS, ~] = system(cmd);
                    if STATUS == 0 && exist(filename, 'file')
                        download_success = true;
                        disp('Data has been downloaded using curl...');
                    end
                catch
                    % curl failed, try next method
                end
            end

            % Method 2: Try wget if curl failed
            if ~download_success && (isunix || ismac)
                try
                    cmd = ['wget -O ' filename ' "' url '"'];
                    [STATUS, ~] = system(cmd);
                    if STATUS == 0 && exist(filename, 'file')
                        download_success = true;
                        disp('Data has been downloaded using wget...');
                    end
                catch
                    % wget failed, try next method
                end
            end

            % Method 3: Try MATLAB websave with options
            if ~download_success
                try
                    options = weboptions('Timeout', 60, ...
                                        'ContentType', 'binary', ...
                                        'CertificateFilename', '');
                    websave(filename, url, options);
                    download_success = true;
                    disp('Data has been downloaded ...');
                catch
                    % websave failed, try final method
                end
            end

            % Method 4: Try urlwrite (older but sometimes works better)
            if ~download_success
                try
                    urlwrite(url, filename); %#ok<URLWR>
                    download_success = true;
                    disp('Data has been downloaded ...');
                catch ME_final
                    % All methods failed
                    error('AllMethodsFailed', ['Could not download using any method: ' ME_final.message]);
                end
            end
        end
        
        % UNZIP
        unzip(filename);
        err_count=0;
    catch ME
        err_count = err_count + 1;
        if err_count>3
            error(ME.identifier, ['Data cannot be downloaded: ' ME.message ...
                '\n\nTroubleshooting tips:' ...
                '\n- Check your internet connection' ...
                '\n- The OSF server may be temporarily unavailable' ...
                '\n- Try downloading manually from: ' url ...
                '\n- Check if a firewall is blocking the connection']);
        end
        % Wait before retry
        pause(2);
        disp(['Download attempt ' num2str(err_count) ' failed. Retrying...']);
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