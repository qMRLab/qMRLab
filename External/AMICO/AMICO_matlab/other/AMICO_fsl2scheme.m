%
% Create a scheme file from bavals+bvecs and write to file.
% If required, b-values can be rounded up to a specific threshold (bstep parameter).
%
function AMICO_fsl2scheme( bvalsFilename, bvecsFilename, schemeFilename, bStep )    
    if nargin < 3
        error( '[AMICO_fsl2scheme] USAGE: AMICO_fsl2scheme <bvalsFilename> <bvecsFilename> <schemeFilename> [bStep]. If bStep is a scalar, round b-values to nearest integer multiple of bStep. If bStep is an array, it is treated as an array of shells in increasing order. B-values will be forced to the nearest shell value.' )
    end
    if nargin < 4
        bStep = 1;
    end
    
    % load files and check size
    bvecs = dlmread( bvecsFilename );
    bvals = dlmread( bvalsFilename );
    if size(bvecs,1) ~= 3 || size(bvals,1) ~= 1 || size(bvecs,2) ~= size(bvals,2)
        error( '[AMICO_fsl2scheme] incorrect/incompatible bval/bvecs files' )
    end

    % if requested, round the b-values
    if length(bStep) == 1 && bStep > 1
        fprintf('-> Rounding b-values to nearest multiple of %d\n', bStep) 
        bvals = round(bvals/bStep) * bStep;
    elseif length(bStep) > 1 
        fprintf('-> Setting b-values to the closest shell in [ ')
        fprintf(' %d ', bStep)
        fprintf(' ]\n') 

        for i = 1:size(bvals,2) 
          [diff, ind] = min(abs(bvals(i) - bStep));

          % warn if b > 99 is set to 0, possible error 
          if (bStep(ind) == 0 && diff > 100) || (bStep(ind) > 0 && diff > bStep(ind) / 20)
            % For non-zero shells, warn if actual b-value is off by more than 5%. For zero shells, warn above 50. Assuming s / mm^2
	    fprintf('   Warning: measurement %d has b-value %d, being forced to %d\n', i, bvals(i), bStep(ind))
          end
         
          bvals(i) = bStep(ind);
 
        end
    end
    
    % write corresponding scheme file
    dlmwrite( schemeFilename, 'VERSION: BVECTOR', 'delimiter','' );
    dlmwrite( schemeFilename, [ bvecs ; bvals ]', '-append', 'delimiter',' ' , 'precision', 6);

    fprintf('-> Writing scheme file to\n   [ %s ]\n', schemeFilename)
end
