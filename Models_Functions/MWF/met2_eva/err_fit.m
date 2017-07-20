function err = err_fit(params, sample, tes)
% return residual

%size(sample)
%size(signal(params, tes))

err = sample - signal(params, tes);
