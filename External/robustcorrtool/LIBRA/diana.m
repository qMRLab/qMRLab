function result = diana(x,vtype,stdize,metric,plots)

%DIANA is a divisive clustering algorithm. It returns a hierarchy of clusters. 
%
% The algorithm is fully described in:
%   Kaufman, L. and Rousseeuw, P.J. (1990),
%   "Finding groups in data: An introduction to cluster analysis",
%   Wiley-Interscience: New York (Series in Applied Probability and
%   Statistics), ISBN 0-471-87876-6.
%
% Required input arguments:
%       x : Data matrix (rows = observations, columns = variables)
%           or Dissimilarity matrix (if number of rows equals 1)
%   vtype : Variable type vector (length equals number of variables)
%           Possible values are 1  Asymmetric binary variable (0/1)
%                               2  Nominal variable (includes symmetric binary)
%                               3  Ordinal variable
%                               4  Interval variable
%          (if x is a dissimilarity matrix, vtype is not required)
%   
% Optional input arguments:
%   stdize : standardise the variables given by the x-matrix
%            Possible values are 0 : no standardisation (default)
%                                1 : standardisation by the mean
%                                2 : standardisation by the median
%            (if x is a dissimilarity matrix, stdize is ignored)
%   metric : Metric used to calculate the dissimilarity matrix
%            Possible values are 0 : Mixed (not all interval variables, default)
%                                1 : Euclidian (all interval variables, default)
%                                2 : Manhattan
%            (if x is a dissimilarity matrix, metric is ignored)
%    plots : draws figures
%            Possible values are 0 : do not create a banner and a cluster tree (default)
%                                1 : create a banner and a cluster tree 
% I/O:
%   result=diana(x,vtype,metric,stdize,plots)
%
% Example: 
%   load agricul.mat
%   result=diana(agricul,[4 4],0,0,1);
%
% The output of DIANA is a structure containing:
%   result.x           : inputmatrix x (only given if x is not a
%                        dissimilarity matrix)
%   result.diss        : text saying whether the inputmatrix x is a dissimilarity matrix
%                        or not
%   result.dys         : calculated dissimilarities (read row by row from the
%                        lower dissimilarity matrix, without the elements of
%                        the diagonal)
%   result.metric      : metric used
%   result.stdize      : standardisation used
%   result.number      : number of observations
%   result.objectorder : order of objects
%   result.heights     : diameter of cluster before deviding it
%                        (= length of banner)
%   result.dc          : divisive coefficient
%   result.merge       : a (n-1) by 2 matrix related to the merge
%
% And DIANA will create a banner and a cluster tree if plots equals 1.
%
% This function is part of LIBRA: the Matlab Library for Robust Analysis,
% available at:
%              http://wis.kuleuven.be/stat/robust.html
%
% Written by Wai Yan Kong 
% Created on 05/2006
% Last Revision: 19/09/2006  

%Checking and filling in the inputs
if (nargin<1)
    error('One input argument required (data or dissimilarity matrix)')
elseif ((nargin<2) & (size(x,1)~=1))
    error('Two input arguments required (datamatrix x and vtype)')
    % so, only datamatrix x as input
elseif (nargin<2)
    metric ='unknown';
    metri=1;
    stdize = 0;
    plots = 0;
    % so, only dissim matrix x as input
elseif (nargin<3)
    stdize = 0;
    plots = 0;
    if (sum(vtype)~=4*size(x,2))
        metri =0; 
        metric='mixed';
    else
        metri = 1;
        metric='euclidean';
    end
    % so, only datamatrix or dissimilarity matrix x and vtype
    % as input
elseif (nargin<4)
    plots = 0;
    if (sum(vtype)~=4*size(x,2))
        metri =0;
        metric='mixed';
    else
        metri =1;
        metric='euclidean';
    end
    % so, only datamatrix or dissimilarity matrix x, vtype and
    % stdize as input
elseif (nargin<5)
    plots = 0;
elseif (nargin>5)
    error('Too many input arguments')
end

% defining metric (for 4 input arguments) and diss
if (nargin>=4)
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

if ((size(x,1)~=1))
    diss=0;
    dissi='x is no dissimilarity matrix';
else
    diss=1;
    dissi='x is a dissimilarity matrix';
end

%Standardization
if (stdize==1) & (metri==1 | metri==2)& diss==0 
    x = ((x - repmat(mean(x),size(x,1),1))./(repmat(std(x),size(x,1),1)));
    standardisation='standardisation by mean';
elseif (stdize==2) & (metri==1  | metri==2) & diss==0 
    x = ((x - repmat(median(x),size(x,1),1))./(repmat(mad(x),size(x,1),1)));
    standardisation='standardisation by median';
elseif(stdize==0)
    standardisation='no standardisation';
elseif (stdize==1 | stdize==2)
    standardisation='no standardisation (not enough num var or x is a diss matrix)';
elseif (nargin<=2)
    standardisation='no standardisation';
else
    error('stdize must be 0,1 or 2');
end

% defining dissimilarity matrix and number
if (diss==1)
    disv=x;
    number=(1+sqrt(1+8*size(x,2)))/2; %number of observations
    % checking for missing values in the dissimilarity matrix
    if any(isnan(disv))
        error('There are missing value(s) in the dissimilarity matrix!')
    end
    % checking the dimensions of the dissimilarity matrix
    if mod(number,fix(number))~=0
        error(['The dimension of the dissimilarity matrix is not correct!'])
    end
else
    resl=daisy(x,vtype,metri);
    disv=resl.dys;
    number=size(x,1);
end

%Actual calculations
[ner,ban,coef,merge,dys]=twinsc(number,[0 disv]',1,2);

% We want ban to be a vector of length n-1
ban(1)=[];

% We want merge to be a (n-1) by 2 matrix
merge2=ones(number-1,2);
for i = 1:(number-1)
    merge2(i,:) = merge(2*i-1:2*i);
end

%Putting things together
result = struct('x',x,'diss',dissi,'dys',dys,'metric',metric,...
    'stdize',standardisation,'number',number,...
    'objectorder',ner,'heights',ban,'dc',coef,'merge',merge2,...
    'class','DIANA');
if diss
    result=rmfield(result, 'x');
end

% Plots
try 
    if plots
        makeplot(result,'classic',0)
    end
catch %output must be given even if plots are interrupted 
    %> delete(gcf) to get rid of the menu 
end
