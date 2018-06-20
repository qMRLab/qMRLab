function [A, T2] = prepare_NNLS(times, t2_range, N)
%----------------------------------------------------------------------
% function prepare_NNLS(times, t2_range, N)
%
% 'times': vector containing each echo time
% 't2_range': T2 range
% 'N'    : number of T2's
%
% Creates the T2 set and matrix
%
% ~~ Charmaine Chia (May 3, 2005) ~~
%
% Modified 05/12/05 (Ives) changed 'range' to 't2_range' to avoid
%     conflict with MATLAB function
%
%----------------------------------------------------------------------

% To change the number of T2 values such that we have N T2s between
% the given t2_range, plus one "T2 dump" value (opposed to N total T2
% values where (N-1) are specified for the t2_range and the Nth one is
% the "T2 dump" value)), change the following syntax's "(N-2)" to "(N-1)".
%T2 = [t2_range(1)*(t2_range(2)/t2_range(1)).^(0:(1/(N-2)):1)'; T2_dump_value]; 
%
% OR simply add a "N = N+1" statement at the beginning of main code.


M = length(times);

% For no T2 offset:
T2 = t2_range(1)*(t2_range(2)/t2_range(1)).^(0:(1/(N-1)):1)';

% generate  A matrix
A = zeros(M,N);
for j = 1:N
  A(:,j) = exp(-times/T2(j))';
end


%%%%%%%%%% From John's Matlab script multi_t2_fit.m %%%%%%%%%%%%
% IF you want 120 T2s, you'll get 119+1 (last T2 # is 10 sec)
%T2 = [range(1)*(range(2)/range(1)).^(0:(1/(N-2)):1)'; 10];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Just trying something new...
% For equally spaced T2 (not useful)
%T2 = [(0.001:0.001:0.1)'; 10];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
