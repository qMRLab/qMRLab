function noisySignal = addNoise(signalVals, SNR, dataFlag)
%ADDNOISE Add noise to data.
%   
%   --args--
%   signalVals: Array of n values. Represents signal values.
%
%   SNR: Double/Int value. Equal to max(signalVals)/stdev('noise')*. (* for
%       'MT' flag, SNR = 1/stdev('noise'), SNR is assumed to be that of the
%       no-MT signal  (1, since signalVals is normalized already).
%
%   dataFlag (optional): String.
%       'magnitude' or 'rician' (default): Add rician noise to signalVals.
%
%       'real' or gaussian': Add gaussian noise to signalVals.
%
%       'mt' or 'MT': Add rician noise to normalized signal (e.g. add 
%                     rician noise to signalVals, divided by (1+rician
%                     noise) (since signalVals is already normalized, no-MT
%                     signal s assumed to be 1).
%
%                     **NOTE** The SAME no-MT signal (1+rician noise) is
%                     used to divide all the signalVals, as if this is a
%                     signle voxel and signalVals are the different
%                     MT-weighted protocol acquisitions.
%
    
    if any( ne(size(SNR), [1 1]) )
        error('addNoise:snrWrongDims', 'SNR parameter must be a single value, not an array');
    end

    % Defaults
    if ~exist('dataFlag','var')
        dataFlag = 'magnitude';
    end

    switch dataFlag
        case {'magnitude', 'rician'}
            noiseSTD = max(signalVals)/SNR;
            noisySignal = ricianNoise(signalVals, noiseSTD);

        case {'real', 'gaussian'}
            noiseSTD = max(signalVals)/SNR;
            noisySignal = signalVals + randn(size(signalVals)) * noiseSTD;

        case {'mt', 'MT'}
            % MT-mode assume that the signalVals are normalized ([0 1]) MT
            % signal vals. As such, the MT-off signal is (semi)arbitrarily
            % set to 1.
            %
            % Some noise  is added to the MT-off (1+noise), and then the
            % signalVals are divided by the noisy MT-off signal (same for
            % all signalVals, as if this data is for a single voxel.
            
            mtOffSignal = 1;
            
            noiseSTD = mtOffSignal/SNR;
            
            noisyMtOffSignal = ricianNoise(mtOffSignal, noiseSTD);
            noisyMtOnSignal  = ricianNoise(signalVals , noiseSTD);
            
            noisySignal = noisyMtOnSignal./noisyMtOffSignal;
        otherwise
            error('addNoise:unknownFlag', 'Flag string (3rd argument) unknown. Run `help addNoise` to see valid flag options.')
    end

end

function noisyMagnitudeData = ricianNoise(signalMag, noiseSTD)
    % Add rician noise to data.
    
    realSig = signalMag + randn(size(signalMag)) * noiseSTD;
    imagSig = 0         + randn(size(signalMag)) * noiseSTD;

    noisyMagnitudeData = sqrt(realSig.^2 + imagSig.^2);
end
