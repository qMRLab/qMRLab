function batch_fitting_single(roifile, protocol, model, outputfile)

%
% function batch_fitting_single(roifile, protocol, model, outputfile)
%
% This function does batch fitting to the voxels in an entire ROI created with
% CreateROI function.
%
% Input:
%
% roifile: the ROI file created with CreateROI
%
% protocol: the protocol object created with FSL2Protocol
%
% model: the model object created with MakeModel
%
% outputfile: the name of the mat file to store the fitted parameters
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%


% first check if there is a file there to resume
if exist(outputfile, 'file')
    load(outputfile);
    if exist('current_index', 'var')
        % previously run and need to be restarted
        current_index = current_index + 1;
        fprintf('Resume an interrupted run from voxel %i\n', current_index);
    else
        % completed
        fprintf('An output file of the same name detected.\n');
        fprintf('Choose a different output file name.\n');
        return;
    end
else
    % if this is the first run
    current_index = 1;
end

% load the roi file
load(roifile);
numOfVoxels = size(roi,1);

% set up the fitting parameter variables if it is the first run
if current_index == 1
    gsps = zeros(numOfVoxels, model.numParams);
    mlps = zeros(numOfVoxels, model.numParams);
    fobj_gs = zeros(numOfVoxels, 1);
    fobj_ml = zeros(numOfVoxels, 1);
    error_code = zeros(numOfVoxels, 1);
    if model.noOfStages == 3
        mcmcps = zeros(numOfVoxels, model.MCMC.samples, model.numParams + 1);
    end
end

tic

fprintf('%i of voxels to fit\n', numOfVoxels-current_index+1);

% start the parallel fitting
for i=current_index:numOfVoxels
    
    fprintf('Fitting voxel %i\n', i);
    
    % get the MR signals for the voxel i
    voxel = roi(i,:)';
    
    % fit the voxel
    if model.noOfStages == 2
        [gsps(i,:), fobj_gs(i), mlps(i,:), fobj_ml(i), error_code(i)] = ThreeStageFittingVoxel(voxel, protocol, model);
    else
        [gsps(i,:), fobj_gs(i), mlps(i,:), fobj_ml(i), error_code(i), mcmcps(i,:,:)] = ThreeStageFittingVoxel(voxel, protocol, model);
    end
    
    % save the temporary results
    if mod(i, 100)==0
        current_index = i;
        if model.noOfStages == 2
            save(outputfile, 'current_index', 'model', 'gsps', 'fobj_gs', 'mlps', 'fobj_ml', 'error_code');
        else
            save(outputfile, 'current_index', 'model', 'gsps', 'fobj_gs', 'mlps', 'fobj_ml', 'mcmcps', 'error_code');
        end
    end
    
end

toc

% save the fitted parameters
if model.noOfStages == 2
    save(outputfile, 'model', 'gsps', 'fobj_gs', 'mlps', 'fobj_ml', 'error_code');
else
    save(outputfile, 'model', 'gsps', 'fobj_gs', 'mlps', 'fobj_ml', 'mcmcps', 'error_code');
end
