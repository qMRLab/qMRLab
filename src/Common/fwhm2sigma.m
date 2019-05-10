function sigmaVal = fwhm2sigma(fwhmVal)
%FWHM2SIGMA 
%   Conversion factor proved here:
%   https://brainder.org/2011/08/20/gaussian-kernels-convert-fwhm-to-sigma/

    conversionFactor = sqrt(8*log(2));

    sigmaVal = fwhmVal./conversionFactor;
end

