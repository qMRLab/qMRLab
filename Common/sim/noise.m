function [ N ] = noise( M, SNR )
%noise Add gaussian noise to data

Max = M;
for ii = 1:length(size(M))
    Max = max(Max);
end

N = M + randn(size(M))/ (SNR/Max);
 
end

