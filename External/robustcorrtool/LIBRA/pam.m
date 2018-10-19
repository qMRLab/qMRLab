function result = pam(x,kclus,vtype,stdize,metric,plots)

%PAM is the Partitioning Around Medoids clustering algorithm.
% It returns a list representing a clustering of the data into kclus
% clusters based on the search for kclus representative objects or medoids among the observations of
% the data set.
%
% The algorithm is fully described in:
%   Kaufman, L. and Rousseeuw, P.J. (1990),
%   "Finding groups in data: An introduction to cluster analysis",
%   Wiley-Interscience: New York (Series in Applied Probability and
%   Statistics), ISBN 0-471-87876-6.
%
% Required input arguments:
%       x : Data matrix (rows = observations, columns = variables)
%           or Dissimilarity vector (if number of columns equals 1). The
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
%     stdize : standardise the variables given by the x-matrix
%              Possible values are 0 : no standardisation (default)
%                                  1 : standardisation by the mean
%                                  2 : standardisation by the median
%              (if x is a dissimilarity matrix, stdize is ignored)
%     metric : Metric to be used 
%              Possible values are 0 : Mixed (not all interval variables, default)
%                                  1 : Euclidean (all interval variables, default)
%                                  2 : Manhattan
%              (if x is a dissimilarity matrix, metric is ignored)
%      plots : draws figures
%              Possible values are 0 : do not create any plot (default)
%                                  1 : create a silhouette plot and a clusplot
%
% I/O:
%   result=pam(x,kclus,vtype,1,1,plots)
%
% Example: 
%   load ruspini.mat
%   result=pam(ruspini,2,[4 4],0,1,1);
%   or:
%   dissim=daisy(ruspini,[4,4],1)
%   result2=pam(dissim.dys,2);
%   makeplot(result2);
%
% The output of PAM is a structure containing:
%   result.dys        : Dissimilarities (read column by column from the
%                       lower dissimilarity matrix)
%   result.metric     : Metric used
%   result.number     : Number of observations
%   result.ttd        : Average silhouette width per cluster
%   result.ttsyl      : Average silhouette width for dataset
%   result.idmed      : Id of medoid observations
%   result.obj        : Objective function at the first two iterations
%   result.ncluv      : Cluster membership for each observation
%   result.clusinf    : Matrix, each row gives numerical information for
%                       one cluster. These are the cardinality of the cluster
%                       (number of observations), the maximal and average
%                       dissimilarity between the observations in the cluster
%                       and the cluster's medoid, the diameter of the cluster
%                       (maximal dissimilarity between two observations of the
%                       cluster), and the separation of the cluster (minimal
%                       dissimilarity between an observation of the cluster
%                       and an observation of another cluster).
%   result.sylinf     : Matrix, with for each observation i the cluster to
%                       which i belongs, as well as the neighbor cluster of i
%                       (the cluster, not containing i, for which the average
%                       dissimilarity between its observations and i is minimal),
%                       and the silhouette width of i. The last column
%                       contains the original object number.
%   result.nisol      : Vector, with for each cluster specifying whether it is
%                       an isolated cluster (L- or L*-clusters) or not isolated.
%                       A cluster is an L*-cluster iff its diameter is smaller than
%                       its separation.  A cluster is an L-cluster iff for each
%                       observation i the maximal dissimilarity between i and any
%                       other observation of the cluster is smaller than the minimal
%                       dissimilarity between i and any observation of another cluster.
%                       Clearly each L*-cluster is also an L-cluster.
%   result.x          : (Standardized) data or Dissimilarity vector (read
%                       row by row)
%   result.class      : 'PAM'
%
% And PAM will create the silhouette plot and the clusplot if plots equals 1
%   (an empty bar indicated by zero in the silhouette plot is a sparse between two clusters).
%
% This function is part of LIBRA: the Matlab Library for Robust Analysis,
% available at:
%              http://wis.kuleuven.be/stat/robust.html
%
% Written by Guy Brys (May 2006)
% Last updated: March 2009 by Sabine Verboven, Mia Hubert

%Checking and filling in the inputs
res1=[];
if (nargin<2)
    error('Two input arguments required')
elseif ((nargin<3) && (size(x,2)~=1) && (size(x,1)~=1))
    error('Three input arguments required')
elseif (nargin<3)
    if (size(x,2)==1)
        x = x';
    end
    res1.metric = 'unknown';
    res1.dys = x;
    lookup=seekN(x);
    res1.number = lookup.numb;   %(1+sqrt(1+8*size(x,1)))/2;
    stdize = 0;
    plots = 0;
elseif (nargin<4)
    stdize = 0;
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
    if (sum(vtype)~=4*size(x,2))
        metri=0;
        metric = 'mixed';
    else
        metri=1;
        metric = 'euclidean';
    end
elseif (nargin<6)
    plots = 0;
end

if nargin>2 && length(vtype)~=size(x,2) 
    error('The variable type vector ''vtype'' has not the same length as the number of variables')
end

% defining metric 
if (nargin>4)
    if (metric==1)
        metric='euclidean';
        metri=1;
    elseif (metric==2)
        metric='manhattan';
        metri=2;
    elseif (metric==0)
        metric='mixed';
        metri=0;
    else
        error('metric must be 0,1 or 2')
    end
end

%Replacement of missing values
for i=1:size(x,1)
    A=find(isnan(x(i,:)));
    if (~(isempty(A)))
        for j=A
            valmisdat=0;
            for c=1:size(x,2)
                if (c~=j)
                    [a,b] = sort(x(:,c));
                    if ~isempty(b(a==x(i,c)))
                        valmisdat=valmisdat+find(a==x(i,c));
                    end
                end
            end
            x(i,j)=prctile(x(isnan(x(:,j))==0,j),100*valmisdat/(size(x,1)*(size(x,2)-1)));
        end
    end
end

%Standardization
if (stdize==1) & metri==1
    x = ((x - repmat(mean(x),size(x,1),1))./(repmat(std(x),size(x,1),1)));
elseif (stdize==2) & metri==1
    x = ((x - repmat(median(x),size(x,1),1))./(repmat(mad(x),size(x,1),1)));
end

%Calculating the dissimilarities with daisy
if (isempty(res1))
    res1=daisy(x,vtype,metri);
end

%Actual calculations (the second for latter use with CLUSPLOT)
[dys,ttd,ttsyl,idmed,obj,ncluv,clusinf,sylinf,nisol]=pamc(res1.number,kclus,[0 res1.dys]');
dys=res1.dys(lowertouppertrinds(res1.number)); % lower dissimilarities matrix read column by column

for c=1:kclus
    avsylwclus(c)=mean(sylinf(sylinf(:,1)==c,3));
end
   
%Putting things together
result = struct('dys',dys,'metric',res1.metric,'number',res1.number,...
    'ttd',avsylwclus,'ttsyl',ttsyl,'idmed',idmed,'obj',obj,'ncluv',ncluv,...
    'clusinf',clusinf,'sylinf',sylinf,'nisol',nisol,'x',x,'class','PAM');

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
