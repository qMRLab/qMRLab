function  = averageEchoesWithWeights(imPhase, imMagnitude, TE)
%AVERAGEECHOESWITHWEIGHTS Combines frequency estimated from every echo with
% weights optimizing SNR. See warning below.
%
% Weights are computed as suggested by Wu et al., 2012
% (doi.org/ 10.1016/j.neuroimage.2011.07.019).
%
% WARNING
% It is still an open question as to how to estimate frequency at every 
% echo. The method implemented here (simple division of phase by TE after
% unwrapping) is very basic and prone to error.


% Unwrap 

end

