function SaveParamsAsNIfTI(paramsfile, roifile, targetfile, outputpref)
%
% function SaveParamsAsNIfTI(paramsfile, roifile, targetfile, outputpref)
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

% load the fitting results
fprintf('loading the fitted parameters from : %s\n', paramsfile);
load(paramsfile);

% load the roi file
fprintf('loading the roi from : %s\n', roifile);
load(roifile);

% load the target volume
fprintf('loading the target volume : %s\n', targetfile);
target = nifti(targetfile);
xsize = target.dat.dim(1);
ysize = target.dat.dim(2);
if length(target.dat.dim) == 2
    zsize = 1;
else
    zsize = target.dat.dim(3);
end
total = xsize*ysize*zsize;

% determine the volumes to be saved
% the number of fitted parameters minus the two fibre orientation
% parameters.
idxOfFitted = find(model.GD.fixed(1:end-2)==0);
noOfVols = length(idxOfFitted);
vols = zeros(total,noOfVols);
% the volume for the objective function values
fobj_ml_vol = zeros(total,1);
% the volume for the error code
error_code_vol = zeros(total,1);
% some special cases
if (strfind(model.name, 'Watson'))
    idxOfKappa = find(ismember(model.paramsStr, 'kappa')==1);
    odi_vol = zeros(total,1);
end

% the volumes for the fibre orientations
fibredirs_x_vol = zeros(total,1);
fibredirs_y_vol = zeros(total,1);
fibredirs_z_vol = zeros(total,1);
% compute the fibre orientations from the estimated theta and phi.
fibredirs = GetFibreOrientation(model.name, mlps);

% determine the volumes with MCMC fitting to be saved
if (model.noOfStages==3)
    idxOfFittedMCMC = find(model.MCMC.fixed(1:end-2)==0);
    noOfVolsMCMC = length(idxOfFittedMCMC);
    volsMCMC = zeros(total,noOfVolsMCMC);

    if (strfind(model.name, 'Watson'))
        idxOfKappa = find(ismember(model.paramsStr, 'kappa')==1);
	     if (model.MCMC.fixed(idxOfKappa)==0)
            odi_volMCMC = zeros(total,1);
        end
    end
end

% convert to volumetric maps
fprintf('converting the fitted parameters into volumetric maps ...\n');
for i=1:size(mlps,1)
    % compute the index to 3D
    volume_index = (idx(i,3)-1)*ysize*xsize + (idx(i,2)-1)*xsize + idx(i,1);
    
    % fitted parameters other than the fiber orientations
    for j=1:length(idxOfFitted)
        vols(volume_index,j) = mlps(i, idxOfFitted(j));
    end
    
    % objective function values
    fobj_ml_vol(volume_index) = fobj_ml(i);
    
    % error codes
    error_code_vol(volume_index) = error_code(i);
    
    % fiber orientations
    fibredirs_x_vol(volume_index) = fibredirs(1,i);
    fibredirs_y_vol(volume_index) = fibredirs(2,i);
    fibredirs_z_vol(volume_index) = fibredirs(3,i);
    
    % special cases
    if (strfind(model.name, 'Watson'))
        odi_vol(volume_index) = atan2(1, mlps(i,idxOfKappa)*10)*2/pi;
    end
    
	 % MCMC fitted parameters
    if (model.noOfStages==3)
        for j=1:length(idxOfFittedMCMC)
            volsMCMC(volume_index,j) = mean(squeeze(mcmcps(i,:,j)));
        end
        if (strfind(model.name, 'Watson'))
            % Warning: Here we hard-coded the index to kappa!!!
            odi_volMCMC(volume_index) = atan2(1, mean(squeeze(mcmcps(i,:,3)))*10)*2/pi;
        end
    end
    
end

% save as NIfTI
fprintf('Saving the volumetric maps of the fitted parameters ...\n');

niftiSpecs.dim = [xsize ysize zsize];
niftiSpecs.mat = target.mat;
niftiSpecs.mat_intent = target.mat_intent;
niftiSpecs.mat0 = target.mat0;
niftiSpecs.mat0_intent = target.mat0_intent;

% the fitted parameters other than the fiber orientations
for i=1:length(idxOfFitted)
    output = [outputpref '_' cell2mat(model.paramsStr(idxOfFitted(i))) '.nii'];
    SaveAsNIfTI(reshape(squeeze(vols(:,i)), [xsize ysize zsize]), niftiSpecs, output);
end

% the special cases
if (strfind(model.name, 'Watson'))
    output = [outputpref '_' 'odi.nii'];
    SaveAsNIfTI(reshape(odi_vol, [xsize ysize zsize]), niftiSpecs, output);
end

% the objective function values
output = [outputpref '_' 'fmin.nii'];
SaveAsNIfTI(reshape(fobj_ml_vol, [xsize ysize zsize]), niftiSpecs, output);

% the error codes
output = [outputpref '_' 'error_code.nii'];
SaveAsNIfTI(reshape(error_code_vol, [xsize ysize zsize]), niftiSpecs, output);

% the fibre orientations
output = [outputpref '_' 'fibredirs_xvec.nii'];
SaveAsNIfTI(reshape(fibredirs_x_vol, [xsize ysize zsize]), niftiSpecs, output);
output = [outputpref '_' 'fibredirs_yvec.nii'];
SaveAsNIfTI(reshape(fibredirs_y_vol, [xsize ysize zsize]), niftiSpecs, output);
output = [outputpref '_' 'fibredirs_zvec.nii'];
SaveAsNIfTI(reshape(fibredirs_z_vol, [xsize ysize zsize]), niftiSpecs, output);

% the MCMC fitted parameters
if (model.noOfStages==3)
    for i=1:length(idxOfFittedMCMC)
        output = [outputpref '_' cell2mat(model.paramsStr(idxOfFittedMCMC(i))) '_MCMC.nii'];
        SaveAsNIfTI(reshape(squeeze(volsMCMC(:,i)), [xsize ysize zsize]), niftiSpecs, output);
    end
    if (strfind(model.name, 'Watson'))
        output = [outputpref '_' 'odi_MCMC.nii'];
        SaveAsNIfTI(reshape(odi_volMCMC, [xsize ysize zsize]), niftiSpecs, output);
    end
end

