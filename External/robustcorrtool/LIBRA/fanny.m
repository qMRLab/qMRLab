function result = fanny(x,kclus,vtype,metric,plots)

%FANNY is a fuzzy clustering algorithm. It returns a list representing a fuzzy clustering of the data
% into kclus clusters.
%
% The algorithm is fully described in:
%   Kaufman, L. and Rousseeuw, P.J. (1990),
%   "Finding groups in data: An introduction to cluster analysis",
%   Wiley-Interscience: New York (Series in Applied Probability and
%   Statistics), ISBN 0-471-87876-6.
%
% Required input arguments:
%       x : Data matrix (rows = observations, columns = variables)
%           or Dissimilarity matrix (if number of columns equals 1). The
%           dissimilarity vector should be obtained by reading row by row from the
%           lower dissimilarity matrix. This can be the result from the
%           function 'daisy'.
%   kclus : The number of desired clusters
%   vtype : Variable type vector (length equals number of variables)
%           Possible values are 1  Asymmetric binary variable (0/1)
%                               2  Nominal variable (includes symmetric binary)
%                               3  Ordinal variable
%                               4  Interval variable
%          (if x is a dissimilarity matrix vtype is not required.)
%
% Optional input arguments:
%     metric : Metric to be used 
%              Possible values are 0: Mixed (not all interval variables, default)
%                                  1: Euclidean (all interval variables, default)
%                                  2: Manhattan
%              (if x is a dissimilarity matrix, metric is ignored)
%      plots : draws figures
%              Possible values are 0 : do not create any plot (default)
%                                  1 : create a silhouette plot and a clusplot
%
% I/O:
%   result=fanny(x,kclus,vtype,metric,plots)
%
% Example: 
%   load country.mat
%   result=fanny(country,2,[4 4],1,0);
%   makeplot(result)
%   or:
%   result=fanny(country,2,[4,4],1,1);
%
% The output of FANNY is a structure containing:
%   result.dys        : dissimilarities (read row by row from the
%                       lower dissimilarity matrix)
%   result.metric     : metric used 
%   result.number     : number of observations
%   result.pp         : Membership coefficients for each observation
%   result.coeff      : Dunn's partition coefficient (and normalized version)
%   result.ncluv      : A vector with length equal to the number of observations,
%                       giving for each observation the number of the cluster to
%                       which it has the largest membership
%   result.obj        : Objective function and the number of iterations the
%                       fanny algorithm needed to reach this minimal value
%   result.sylinf     : Matrix, with for each observation i the cluster to
%                       which i belongs, as well as the neighbor cluster of i
%                       (the cluster, not containing i, for which the average
%                       dissimilarity between its observations and i is minimal),
%                       and the silhouette width of i. The last column
%                       contains the original object number.
%
% FANNY will create the silhouette plot and the clusplot if plots equals 1
%   (an empty bar indicated by zero in the silhouette plot is a sparse
%   between two clusters).
%
% This function is part of LIBRA: the Matlab Library for Robust Analysis,
% available at:
%              http://wis.kuleuven.be/stat/robust.html
%
% Written by Guy Brys and Wai Yan Kong (May 2006)
% Last update: March 2009

%Checking and filling in the inputs
res1=[];
if (nargin<2)
    error('Two input arguments required')
elseif (nargin<3) && (size(x,2)~=1 & size(x,1)~=1)
    error('Three input arguments required')
elseif (nargin<3)
    if (size(x,2)==1)
        x = x';
    end
    res1.metric = 'unknown';
    res1.dys = x;
    lookup=seekN(x);
    res1.number = lookup.numb; %(1+sqrt(1+8*size(x,1)))/2;
    plots = 0;
elseif (nargin<4)
    plots = 0;
    if (sum(vtype)~=4*size(x,2))
        metri=0;
        metric = 'mixed';
    else
        metri=1;
        metric = 'euclidean';
    end
elseif (nargin<5)
    plots = 0;
end

% defining metric (for 4 input arguments) and diss
if (nargin>=5)
    if (metric==1)
        metri=1;
        metric='euclidean';
    elseif (metric==2)
        metri=2;
        metric='manhattan';
    elseif (metric==0)
        metri=0;
        metric='mixed';
    else
        error('metric must be 0,1 or 2')
    end
end


%Calculating the dissimilarities with daisy
%For fanny the second command is also required
if (isempty(res1))
    res1=daisy(x,vtype,metri);
end
res1.dys=res1.dys(lowertouppertrinds(res1.number));

%Actual calculations
[pp,coeff,clu,obj,sylinf]=fannyc(res1.number,kclus,[0 res1.dys]');

%Putting things together
result = struct('dys',res1.dys,'metric',res1.metric,...
    'number',res1.number,'pp',pp,...
    'coeff',coeff,'ncluv',clu,'obj',obj,'sylinf',sylinf,'x',x,'class','FANNY');

% Plots
try 
    if plots
        makeplot(result,'classic',0)
    end
catch %output must be given even if plots are interrupted 
    %> delete(gcf) to get rid of the menu 
end
%------------
%SUBFUNCTIONS

function dv = lowertouppertrinds(n)

dv=[];
for i=0:(n-2)
    dv = [dv cumsum(i:(n-2))+repmat(1+sum(0:i),1,n-i-1)];
end

%---
function outn = seekN(x)

ok=0;
numb=0;
k=size(x,2);
sums=cumsum(1:k);
for i=1:k
    if(sums(i)==k)
        numb=i+1;
        ok=1;
    end
end
outn=struct('numb',numb,'ok',ok);
