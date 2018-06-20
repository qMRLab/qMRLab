function [spectrum, chi2_NNLS] = do_NNLS(decay_matrix, measurements, sigma)

%-------------------------------------------------------------------
% function [s_NNLS, chi2_NNLS, T2] = do_NNLS(times, range, N, decay, sigma, mu)
%
% * Runs through non-regularized NNLS 
%
%-------------------------------------------------------------------

% compute default tolerance used by lsqnonneg (as per help lsqnonneg )
default_tolx = 10*max(size(decay_matrix))*norm(decay_matrix,1)*eps;
% initialize fitting options structure
opts = optimset('TolX',default_tolx);

[spectrum, bla, blo, exitflag, output] = lsqnonneg(decay_matrix,  measurements');

% if num of iterations exceeded
while ~exitflag
    % increase the tolerance
    opts = optimset(opts,'TolX',opts.TolX*10);
    % re-fit
    [spectrum, bla, blo, exitflag] = lsqnonneg(decay_matrix, measurements', opts);
end


chi2_NNLS = sum((decay_matrix*spectrum - measurements').^2)/sigma^2;
