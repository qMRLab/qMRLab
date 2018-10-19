function result=L1median(x,tol);

%L1MEDIAN is an orthogonally equivariant location estimator,
% also known as the spatial median. It is defined as the point which
% minimizes the sum of the Euclidean distances to all observations in the
% data matrix x. It can resist 50% outliers. 
%
% Reference (for the algorithm): 
%    Hossjer, O. and Croux, C. (1995)
%    "Generalizing univariate signed rank statistics for testing and estimating 
%    a multivariate location parameter", Nonparametric Statistics, 4, 293-308.
%
% Required input argument:
%    x : either a data matrix with n observations in rows, p variables in columns
%        or a vector of length n.
%
% Optional input argument:
%  tol : convergence criterium; the iterative process stops when the norm between two solutions < tol.
%        (default = 1.e-08).
%
% I/O: result=L1median(x,tol);
%
% This function is part of LIBRA: the Matlab Library for Robust Analysis,
% available at: 
%              http://wis.kuleuven.be/stat/robust.html
%
% Original Gauss code by C. Croux, translated to MATLAB by Sabine Verboven
% Last updated 06/02/2009 by Mia Hubert

if nargin <2
   tol=1.e-08;
end;
[n,p]=size(x);
maxstep=200;
%initializing starting value for m
m=median(x);
k=1;
obj=mrobj(x,m);
while (k<=maxstep)
   mold=m;
   objold=obj;
   centerx=x-repmat(m,n,1);
   nc=norme(centerx);
   w=nc;
   ind=1:n;
   notzero=ind(nc~=0);
   w(notzero)=1./nc(notzero);
   delta=sum(centerx.*repmat(w,1,p),1)./sum(w);
   nd=norme(delta);
   if all(nd<tol)
      maxhalf=0;
   else
      maxhalf=log2(nd/tol);
   end
   m=mold+delta;   %computation of a new estimate
   nstep=0;
   obj=mrobj(x,m);
   while all(obj>=objold)&(nstep<=maxhalf)
      nstep=nstep+1;
      m=mold+delta./(2^nstep);
   end
   if (nstep>maxhalf)
      mX=mold;
      break
   end
   k=k+1;
end
if k>maxstep
   display('Iteration failed')
end
result=m;

%------------------------------------------------------------------
function n=norme(x);

%NORME calculates the Euclidian norm of a matrix x
% the output is a column vector containing the norm of each row
% I/O: n=norme(x);

n=sqrt(sum(x.^2,2));

%------------------------------------------------------------------
function s=mrobj(x,m)

%MROBJ computes the objective function in m based on x and a

xm=norme(x-repmat(m,size(x,1),1));
s=sum(xm,1)';

