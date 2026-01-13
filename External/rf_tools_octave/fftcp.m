%
%  A centered FFT, padded with zeros to a specified length
%
%  hf = fftcp(h,n)
%
%    h  -- input waveform
%    n  -- fft length
%
%    hf -- centered, padded fft of h
%

%  written by John Pauly, 1992
%  (c) Board of Trustees, Leland Stanford Junior University

function hf = fftcp(h,n)

l = length(h);
hf = fftc([zeros(1,ceil(n/2-l/2)) h zeros(1,floor(n/2-l/2))]);

