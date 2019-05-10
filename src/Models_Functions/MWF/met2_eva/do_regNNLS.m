function [reg_spectrum, chi2_regNNLS] = do_regNNLS(decay_matrix, measurements, sigma, mu)

%-------------------------------------------------------------------
% function [s_NNLS, chi2_NNLS] = do_regNNLS(num_t2_vals, decay_matrix, measurements, sigma, mu)
%
% * Runs through regularized NNLS (energy)
%
% ~~~ Charmaine Chia (May 3, 2005) ~~~
%-------------------------------------------------------------------

% generate minimum energy regularization
num_t2_vals = size(decay_matrix,2);
H = eye(num_t2_vals);
H_temp = mu*H;
this_decay_matrix = [decay_matrix; H_temp];
this_data = [measurements'; zeros(num_t2_vals,1)];

%-------------------------------------------------------------------
% --- EAO: addition to fit 2D spectrum (T2* times, with freq. offsets)
%-------------------------------------------------------------------
fit_delf = 1;

if fit_delf == 1
    
    % compute default tolerance used by lsqnonneg (as per help lsqnonneg )
    default_tolx = 10*max(size(this_decay_matrix))*norm(this_decay_matrix,1)*eps;
    % initialize fitting options structure
    opts = optimset('TolX',default_tolx);

    [reg_spectrum, bla, blo, exitflag, output] = lsqnonneg(this_decay_matrix,  this_data);

    % if num of iterations exceeded
    while ~exitflag
        % increase the tolerance
        opts = optimset(opts,'TolX',opts.TolX*10);
        % re-fit
        [reg_spectrum, bla, blo, exitflag] = lsqnonneg(this_decay_matrix, this_data, opts);
    end

else
    reg_spectrum = lsqnonneg(this_decay_matrix, this_data);
end
%-------------------------------------------------------------------




chi2_regNNLS = sum((this_decay_matrix*reg_spectrum - this_data).^2)/sigma^2;



