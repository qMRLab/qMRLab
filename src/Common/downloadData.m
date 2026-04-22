function dataPath = downloadData(Model, path, method, attempts, timeout)
% Downlaod example data for a given qMRLab model
%
%   DATAPATH = downloadData(MODEL, PATH)
%   DATAPATH = downloadData(MODEL, PATH, METHOD, ATTEMPTS, TIMEOUT)
%
% The function will create a 'PATH/NAME_demo' folder(where NAME is the model name),
% cd into it, download data from the URL specified in MODEL.onlineData_url,
% and unzip it into a structure:
%
%   PATH/NAME_demo:
%   ├─ NAME_data
%   |   ├─ [*.zip original download]
%   |   └─ [*.nii.gz model input maps]
%   └─ FitResults
%       ├─ FitResults.mat
%       └─ [*.nii.gz model output maps]
%
% Inputs:
%   MODEL: A qMRLab model object (e.g. T1map, MWF, etc.)
%   PATH: (optional) A directory where the data should be downloaded.
%       If not provided, a dialog will prompt the user to select a directory.
%   METHOD: (optional) One of {'auto', 'curl', 'wget', 'websave', 'request', 'urlwrite'},
%       the default 'auto' will try all other methods in order.
%   ATTEMPTS: (optional) max download attempts, defaults to 5.
%   TIMEOUT: (optional) connection timeout in seconds, defaults to 60.
%
% Output:
%   DATAPATH: The path to the downloaded data folder: ./NAME_data

METHODS = struct(...
    'auto', @downloadAuto, ...
    'curl', @downloadWithCurl, ...
    'wget', @downloadWithWget, ...
    'websave', @downloadWithWebsave, ...
    'request', @downloadWithRedirects, ...
    'urlwrite', @downloadWithUrlwrite ...
);

% Unit-testing backdoor, see Test/Common/downloadData_Test.m
if nargin == 1 && isequal(Model, 'localfunctions')
    dataPath = METHODS;
    return;
end

if ~exist('path','var') || isempty(path)
    h = msgbox('Please select a destination to create example folder.','qMRLab');
    waitfor(h);
    path = uigetdir(); % Save batch example to this dir
end
if ~path, dataPath = []; return; end

if ~exist('method','var') || isempty(method)
    method = 'auto';
end

if ~exist('attempts','var') || isempty(attempts)
    attempts = 5;
end

if ~exist('timeout', 'var') || isempty(timeout)
    timeout = 60;
end

method = lower(method);
if ~ismember(method, fieldnames(METHODS))
    error('qMRLab:download:method', 'Invalid method. Choose from: %s', strjoin(fieldnames(METHODS), ', '));
end

cd(path);
path = '.'; % use relative path

mkdir([Model.ModelName '_demo']);
cd([Model.ModelName '_demo']);

try
    url = Model.onlineData_url;
catch
    warning(['No dataset for ' Model.ModelName])
    dataPath = [Model.ModelName '_data'];
    return
end
filename = [Model.ModelName '.zip'];

disp('Please wait. Downloading data ...');
for err_count = 1:attempts
    try
        % DOWNLOAD
        METHODS.(method)(url, filename, timeout);
        disp('Download successful. Unzipping data ...');

        % UNZIP
        unzip(filename);
        break
    catch ME
        disp(['Download attempt ' num2str(err_count) ' failed.']);
        if err_count >= attempts
            error('qMRLab:download:fail', ...
                ['Data cannot be downloaded after ' num2str(attempts) ' attempts: ' ME.message ...
                '\n\nTroubleshooting tips:' ...
                '\n- Check your internet connection' ...
                '\n- The OSF server may be temporarily unavailable' ...
                '\n- Try downloading manually from: ' url ...
                '\n- Check if a firewall is blocking the connection']);
        end
    end

    % Wait before retry
    disp('Retrying...');
    pause(2);
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

function downloadAuto(url, filename, timeout)
% Try multiple methods to handle OSF redirects (308 status)

    if moxunit_util_platform_is_octave
        if isunix && ~isempty(getenv('ISCITEST')) && str2double(getenv('ISCITEST')) % issue #113 --> no outputs on TRAVIS
            downloadWithCurl(url, filename, timeout)
        else
            downloadWithUrlwrite(url, filename, timeout)
        end
    else
        % Method 1: Try system curl (most reliable for redirects)
        if isunix || ismac
            try
                downloadWithCurl(url, filename, timeout)
                return;
            catch
                % curl failed, try next method
            end
        end

        % Method 2: Try wget if curl failed
        if isunix || ismac
            try
                downloadWithWget(url, filename, timeout)
                return;
            catch
                % wget failed, try next method
            end
        end

        % Method 3: Try MATLAB websave with options
        try
            downloadWithWebsave(url, filename, timeout)
            return;
        catch
            % websave failed, try next method
        end

        % Method 4: Try custom redirect handler
        try
            downloadWithRedirects(url, filename, timeout);
            return;
        catch
            % custom redirect handler failed, try final method
        end

        % Method 5: Try urlwrite (older but sometimes works better)
        try
            downloadWithUrlwrite(url, filename, timeout);
        catch ME_final
            % All methods failed
            error(['Could not download using any method: ' ME_final.message]);
        end
    end
end

function downloadWithCurl(url, filename, timeout)
% Download using system curl (most reliable for redirects)

    cmd = sprintf('curl -L --connect-timeout %d -o "%s" "%s"', timeout, filename, url);
    [STATUS, MESSAGE] = system(cmd);
    if STATUS == 0 && exist(filename, 'file')
        disp('Data has been downloaded using curl...');
    end
    if STATUS, error(MESSAGE); end
end

function downloadWithWget(url, filename, timeout)
% Download using system wget (alternative for redirects)

    cmd = sprintf('wget --timeout=%d -O "%s" "%s"', timeout, filename, url);
    [STATUS, MESSAGE] = system(cmd);
    if STATUS == 0 && exist(filename, 'file')
        disp('Data has been downloaded using wget...');
    end
    if STATUS, error(MESSAGE); end
end

function downloadWithWebsave(url, filename, timeout)
% Download using MATLAB websave with options

    options = weboptions('Timeout', timeout, ...
                        'ContentType', 'binary', ...
                        'CertificateFilename', '');
    websave(filename, url, options);
    disp('Data has been downloaded using websave...');
end

function downloadWithUrlwrite(url, filename, timeout)
% Download using urlwrite (older but sometimes works better)

    urlwrite(url, filename, 'Timeout', timeout); %#ok<URLWR>
    disp('Data has been downloaded ...');
end

function downloadWithRedirects(url, outputFile, timeout, maxRedirects)
% Download a file following HTTP redirects manually
%   WEBSAVE struggles with the chain 301 -> 308 -> 302 required
%   for some OSF paths.

    if nargin < 4
        maxRedirects = 10;
    end

    currentUrl = url;
    redirectCount = 0;

    while redirectCount < maxRedirects
        request = matlab.net.http.RequestMessage('GET');
        uri = matlab.net.URI(currentUrl);
        options = matlab.net.http.HTTPOptions('ConnectTimeout', timeout);

        try
            response = send(request, uri, options);
        catch ME
            error('Failed to connect to %s: %s', currentUrl, ME.message);
        end

        statusCode = response.StatusCode;

        if statusCode == 200
        % Success! Write the file

            fid = fopen(outputFile, 'wb');
            fwrite(fid, response.Body.Data, 'uint8');
            fclose(fid);

            finfo = dir(outputFile);
            fprintf('Download successful: %d bytes\n', finfo.bytes);
            return;

        elseif statusCode == 301 || statusCode == 302 || statusCode == 307 || statusCode == 308
        % Follow redirect

            locationHeader = response.Header([response.Header.Name] == "Location");
            if isempty(locationHeader)
                error('Redirect response without Location header');
            end

            currentUrl = string(locationHeader.Value);
            redirectCount = redirectCount + 1;
            fprintf('Redirect: %s -> %s\n', url, currentUrl);

        else
            error('Unexpected status code: %d', statusCode);
        end
    end
    error('Too many redirects (max %d)', maxRedirects);
end
