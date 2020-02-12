OSF_link = "https://osf.io/e5sdb/download/";


TI = [33, 100, 300, 900, 2700, 5000];

dataType = "Magnitude"

cmd = ['curl -L -o rrsg_dataset.zip', ' ', OSF_link];
[STATUS,MESSAGE] = unix(cmd);
unzip('rrsg_dataset.zip', 'data/');

try
    cd qMRLab
    startup
    cd ..
catch
    error("qMRLab could not be started correctly.")
end

% Reset dataCheckPassed variable
dataCheckPassed = [];

try 
    %% Check that the files have the correct names 
    if exist('data/ir_data.nii.gz')
         % File exists.
    else
       error("Your OSF data must contain a file called ir_data.nii.gz, and it doesn't.")
    end

    % Load files
    try
        data = load_nii_data('data/ir_data.nii.gz');
    catch
        error("ir_data.nii.gz could not be loaded correctly.")
    end
    try
        mask = load_nii_data('data/mask.nii.gz');
    catch
        error("mask.nii.gz could not be loaded correctly.")
    end


    % Check the dimensions of the files
    if size(data, 4) ~= length(TI)
        error("The fourth dimension of your `data` variable should be the same size as the number of TIs, but it isn't.")
    end
    
    % If you got here, all tests passed
    dataCheckPassed = true;
catch err
    error(err)
    dataCheckPassed = false;
end

if dataCheckPassed
    disp("All data format check passed, you can continue to the next step of the script.")
else
    disp("At least one data format check did not pass. Please review our submission guidelines, and reupload your data to OSF.")
end

% Assign data to variables needed for qMRLab module
IRData = data;
Mask = mask;


% Format qMRLab inversion_recovery model parameters, and load them into the Model object
Model = inversion_recovery; 

% Set the customizable settings in the model
Model.Prot.IRData.Mat = [TI'];
Model.options.method = dataType;

% Format data structure so that they may be fit by the model
data = struct();
data.IRData= double(IRData);
data.Mask= double(Mask);

FitResults = FitData(data,Model,0); % The '0' flag is so that no wait bar is shown.


