function [reg_spectrum,chi2_regNNLS] = iterate_NNLS(mu,chi2_min,chi2_max,...
          measurements,decay_matrix,chi2_NNLS,sigma)
%----------------------------------------------------------------------
%% Changes to value of "mu" (smaller steps)
%% mu/5 -> mu/2
%% mu*4 -> mu*1.9
%
%  Iterates through various "mu" until chi2 condition is satisfied.
% 
% ~~ Charmaine Chia (April 12, 2005) ~~
%----------------------------------------------------------------------
%-----------     Run regularization with parameters   -------------%
[reg_spectrum, chi2_regNNLS] = do_regNNLS(decay_matrix, measurements, sigma, mu);

%------------    Calculate corresponding chi2 range   -------------%
diff = (100*(chi2_regNNLS - chi2_NNLS)/chi2_NNLS);

%--------  Check to see if within the specified chi2 range --------%
%-- Iterate thru this fcn w/ diff "mu" until condition satisfied --%


while ((diff>chi2_max)||(diff<chi2_min))
   if (diff>chi2_max)
       mu = mu/2;
    elseif (diff<chi2_min)
       mu = 1.9*mu;
   end
    % disp(fprintf('mu = %f, chi2 = %f, diff = %f (chi2 LOW)\n', mu,chi2_regNNLS,diff));
     [reg_spectrum, chi2_regNNLS] = do_regNNLS(decay_matrix, measurements, sigma, mu);
     diff = (100*(chi2_regNNLS - chi2_NNLS)/chi2_NNLS);
end

%disp(fprintf('DONE!  mu = %f, chi2= %f, diff  = %f\n', mu, chi2_regNNLS,diff));

% if diff > chi2_max,
%   disp(fprintf('mu = %f, chi2 = %f, diff = %f (chi2 HIGH)\n', mu,chi2_regNNLS,diff));
%   [reg_spectrum,chi2_regNNLS] = ...
%       iterate_NNLS(mu/2,chi2_min,chi2_max,num_t2_vals,measurements,decay_matrix,chi2_NNLS,sigma);
% elseif diff < chi2_min,
%   disp(fprintf('mu = %f, chi2 = %f, diff = %f (chi2 LOW)\n', mu,chi2_regNNLS,diff));
%   [reg_spectrum,chi2_regNNLS] = ...
%       iterate_NNLS(mu*1.9,chi2_min,chi2_max,num_t2_vals,measurements,decay_matrix,chi2_NNLS,sigma);
% 
% elseif and(diff>chi2_min, diff<chi2_max),
%   %sprintf('mu = %f, chi2 = %f  ==> Keep bringing mu down', mu, chi2_regNNLS)
%   %[s_regNNLS,mu,chi2_regNNLS]=iterate_NNLS_fine(decay,times,chi2,sigma,mu,0);
%   %sprintf('A match!  ==>  mu = %f; chi2 = %f', mu,chi2_regNNLS)
%   new_mu = mu;
%   disp(fprintf('DONE!  mu = %f, chi2= %f, diff  = %f\n', mu, chi2_regNNLS,diff));
%   return
% %elseif new_mu == 0 %Trying to fix prob where unreg has no x^2
% else
%     disp(fprintf('Houston, we have a problem!'));
% end



%-----------------------------END-----------------------------------%