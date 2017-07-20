function sigma = EstimateSigma(signal, protocol, model)
%
% function sigma = EstimateSigma(signal, protocol, model)
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

if model.sigma.perVoxel == 1
    sigma = std(signal(protocol.b0_Indices), 1);
    % if lower than the minimum SNR
    sigmaMin = model.sigma.minSNR*mean(signal(protocol.b0_Indices));
    if sigma < sigmaMin
        sigma = sigmaMin;
    end
else
    if isfield(model.sigma, 'globalSigma')
        sigma = model.sigma.globalSigma;
    elseif isfield(model.sigma, 'globalSNR')
        sigma = model.sigma.globalSNR*mean(signal(protocol.b0_Indices));
    else
        disp('You have chosen not to use per voxel sigma estimate');
        error('You need to specify either sigma.globalSigma or sigma.globalSNR for your model');
    end
end

% apply the scaling parameter that may improve fitting
sigma = sigma/model.sigma.scaling;
