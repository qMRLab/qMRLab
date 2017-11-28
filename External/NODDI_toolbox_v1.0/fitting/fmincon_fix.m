function [x,fval,exitflag,output,lambda,grad,hessian] = fmincon_fix(fix,fun,x0,A,b,Aeq,beq,lb,ub,nonlcon,options,varargin)
% Wrapper for fmincon that allows the user to specify a number of model
% parameters that remain fixed to the initial settings.
%
% fix is a binary array.  Zero indicates that the parameter in the
% corresponding position in x0 varies during fitting; one indicates that
% the value remains fixed at the alue in x0.
%
% The other parameters are all as for fmincon.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%

% Construct the parameter vector with fixed values removed.
x0f = x0(find(fix==0));

% Run the opt.
[x,fval,exitflag,output,lambda,grad,hessian] = fmincon(fun,x0f,A,b,Aeq,beq,lb,ub,nonlcon,options,varargin{:}, fix, x0);

% Reconstruct the full fitted parameter list including the fixed values.
xf = fix.*x0;
xf(find(fix==0)) = x;
x = xf;
