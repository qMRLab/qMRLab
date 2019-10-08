function freqEstimate = averageEchoesWithWeights(imPhase, imMagnitude, TE)
%AVERAGEECHOESWITHWEIGHTS Combines frequency estimated from every echo with
% weights optimizing SNR. See WARNING below.
%
% Weights are computed as suggested by Wu et al., 2012
% (doi.org/ 10.1016/j.neuroimage.2011.07.019).
%
% imPhase: 4D magnitude image with multiple echoes on 4th dim
% imMagnitude: 4D magnitude image with multiple echoes on 4th dim
% TE: vector containing all echo times
%
% freqEstimate: Weighted average of the frequencies
%
% WARNING:
% It is still an open question as to how to estimate frequency at every 
% echo. The method implemented here (simple division of phase by TE after
% unwrapping) is very basic and prone to error. It does not take into
% account a possible phase offset and 2pi integers that could be introduced
% between echoes by spatial unwrapping.


% Spatially unwrap phase
disp('Started   : Laplacian phase unwrapping ...');
for iEcho = numel(TE):-1:1
    imPhaseUw(:,:,:,iEcho) = unwrapPhaseLaplacian(imPhase(:,:,:,iEcho));
end
disp('Completed : Laplacian phase unwrapping');
disp('-----------------------------------------------');

% Compute weights
TE = reshape(TE, [1,1,1,numel(TE)]); % For broadcasting
weights = TE .* imMagnitude;
weights = weights ./ sum(weights,4);
weights(~isfinite(weights)) = 0;

% Average frequencies with weights
freqEstimate = sum(imPhaseUw ./ TE .* weights, 4);

end

