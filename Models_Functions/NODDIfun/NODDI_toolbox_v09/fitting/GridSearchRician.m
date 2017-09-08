function [x0, liks] = GridSearchRician(Epn, model, grid, protocol, constants, initSig, fixT1, fibredir)
% Performs a discrete grid search for the combination of parameters
% that best fits a set of measurements for the specified model using a
% Rician noise model.
%
% [x0, liks] = GridSearchRician(Epn, model, grid, protocol, constants, initSig, fibredir)
% returns the parameter combination x0 with the lowest fitting error and a list
% liks of the values of the objective function for each parameter combination in the grid.
%
% model is a string specifying the model.
%
% Epn is the array of measurements.
%
% model is a string specifying the model
%
% grid is the list of parameter combinations to check; typically
% this comes from GetSearchGrid.
% 
% protocol contains the protocol for obtaining the measurements.
%
% constants contains values required for the model signal computations.
%
% initSig is the standard deviation of the noise underlying the Rician
% noise model.
%
% fibredir can be specified, but if left out is estimated by fitting the
% diffusion tensor model to the measurements and using the principal
% eigenvalue.
%
% fixT1 is a fixed value for T1 that can be specified.  If not
% specified and the model is one that contains T1 as a parameter,
% then T1 is estimated via a linear fit at the same time as the
% diffusion tensor.  Note: this may not work particularly well.
% If the DT is a bad fit for the data, this can easily result
% in negative diffusivities etc.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

[junk numCombs] = size(grid);

% Find the fiber direction and S0 from the best fit DT
if(nargin<8)
    if(strcmp(model, 'CylSingleRadIsoDotTortIsoV_GPD_B0T1'))
        if(nargin<7)
                D = FitLinearDT_T1(Epn, protocol);
                % Linear estimate of T1 can occasionally go negative
                % from noise.
                T1 = max([0 D(8)]);
        else
                % Correct for the known T1 and fit DT in the normal way.
                D = FitLinearDT(Epn.*exp(-fixT1./protocol.TM), protocol);
                T1 = fixT1;
        end
    else
        D = FitLinearDT(Epn, protocol);
    end
    dt = MakeDT_Matrix(D(2), D(3), D(4), D(5), D(6), D(7));
    [evec, eval] = eig(dt);
	 % try to deal with non-positive definite tensors
    [eigs, ind] = sort(abs([eval(1, 1) eval(2, 2) eval(3, 3)]));
    fibredir = evec(:,ind(3));
    if(strncmp(model, 'Bingham', 7))
        beta_to_kappa = eigs(2)/eigs(3);
        fanningdir = evec(:,ind(2));
    end
    S0 = exp(D(1));
end

initTheta = acos(fibredir(3));
initPhi = atan2(fibredir(2), fibredir(1));

if(strncmp(model, 'Bingham', 7))
    if abs(fibredir(3)) > 0.1
        mat = [-sin(initPhi) -cos(initTheta)*cos(initPhi); cos(initPhi) -cos(initTheta)*sin(initPhi)];
        tmp = mat\[fanningdir(1) fanningdir(2)]';
        initPsi = atan2(tmp(2), tmp(1));
    elseif abs(sin(initPhi)) > 0.1
        mat = [-sin(initPhi) -cos(initTheta)*cos(initPhi); 0 sin(initTheta)];
        tmp = mat\[fanningdir(1) fanningdir(3)]';
        initPsi = atan2(tmp(2), tmp(1));
    else
        mat = [cos(initPhi) -cos(initTheta)*sin(initPhi); 0 sin(initTheta)];
        tmp = mat\[fanningdir(2) fanningdir(3)]';
        initPsi = atan2(tmp(2), tmp(1));
    end
    if(strcmp(model, 'BinghamStickTortIsoV_B0'))
        grid(4,:) = grid(3,:)*beta_to_kappa;
        grid(5,:) = initPsi;
    elseif(strcmp(model, 'BinghamCylSingleRadTortIsoV_GPD_B0'))
        grid(5,:) = grid(4,:)*beta_to_kappa;
        grid(6,:) = initPsi;
    else
        error('ERROR: Bingham initialization not implemented for this model');
    end
end

% Add the b=0 measurement to the test combinations for models that need it.
if(strcmp(model, 'CylSingleRadIsoV_GPD_B0') ||...
   strcmp(model, 'CylSingleRadTortIsoV_GPD_B0') ||...
   strcmp(model, 'CylSingleRadIsoDotTortIsoV_GPD_B0') ||...
   strcmp(model, 'WatsonSHCylSingleRadTortIsoV_GPD_B0') ||...
   strcmp(model, 'WatsonSHStickIsoV_B0') ||...
   strcmp(model, 'WatsonSHStickIsoVIsoDot_B0') ||...
   strcmp(model, 'WatsonSHStickTortIsoV_B0') ||...
   strcmp(model, 'WatsonSHStickTortIsoVIsoDot_B0') ||...
   strcmp(model, 'BinghamStickTortIsoV_B0') ||...
   strcmp(model, 'BinghamCylSingleRadTortIsoV_GPD_B0') ||...
   strcmp(model, 'StickIsoV_B0') ||...
   strcmp(model, 'StickTortIsoV_B0'))
        grid = [grid' ones(size(grid,2), 1)*S0]';
end

% Add T1 and the b=0 measurement to the test combinations for models
% that need it.
if(strcmp(model, 'CylSingleRadIsoDotTortIsoV_GPD_B0T1'))
        grid = [grid' ones(size(grid,2), 1)*S0 ones(size(grid,2), 1)*T1]';
end

% Test each combination
liks = zeros(numCombs, 1);
for j=1:numCombs
    Eest = SynthMeas(model, grid(:,j), protocol, fibredir, constants);
    liks(j) = RicianLogLik(Epn, Eest, initSig);
end
[a ind] = max(liks);
mlPars = grid(:,ind);

% Rescale and construct the final result.
scale = GetScalingFactors(model);
psc = [mlPars' initSig].*scale;
x0 = [psc(1:(end-1)) initTheta initPhi initSig];

