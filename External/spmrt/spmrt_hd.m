function HD = spmrt_hd(x,q)

% Compute the Harrell-Davis estimate of the qth decile
%
% FORMAT HD = spmrt_hd(x,q)
%
% INPUT  x is a vector or a matrix, in this case HD estimates are computed column-wise
%          note that matrices can contain NaN - and this is accounted for
%        q is the decile to compute (default is the median q=0.5)
%
% OUTPUT HDQ is/are the decile(s)
%
% FRANK E. HARRELL and C. E. DAVIS (1982).
% A new distribution-free quantile estimator
% Biometrika 69 (3): 635-640. doi: 10.1093/biomet/69.3.635
% ----------------------------------------------------------------------

if size(x,1) == 1;
    x=x';
end
n=size(x,1);
m1=(n+1).*q;
m2=(n+1).*(1-q);
vec=1:n;
w=betacdf(vec./n,m1,m2)-betacdf((vec-1)./n,m1,m2);
y=sort(x,1);
HD=sum(repmat(w',1,size(y,2)).*y,1);


