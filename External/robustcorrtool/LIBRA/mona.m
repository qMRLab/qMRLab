function result=mona(x,plots)

%MONA returns clusters according to mona (monothetic
% clustering)
%
% The algorithm is fully described in:
%   Kaufman, L. and Rousseeuw, P.J. (1990),
%   "Finding groups in data: An introduction to cluster analysis",
%   Wiley-Interscience: New York (Series in Applied Probability and
%   Statistics), ISBN 0-471-87876-6.
%
% Required input argument:
%  x : Data matrix (rows = observations, columns = variables)
%      containing only binary values.
%      Missing values are indicated by the value 2.
%
% Optional input argument:
%  plots : if equal to 1 a banner is drawn (default = 0)
%
% I/O:
%   result=mona(x,1)
%
% Example (subtracted from the referenced book)
%   load animal.mat
%   result=mona(animal,1);
%
% The output of MONA is a structure containing
%   result.matrix          : revised inputmatrix (contains only 0 and 1 and missing
%                            values are estimated)
%   result.number          : number of observations
%   result.var             : number of variables
%   result.ner             : order of objects
%   result.lava            : variable used for separation
%   result.separationstep  : separation step
%                            (The value on the ith index is the stepnumber from
%                            the seperation of the elements with index 1 to i
%                            from the elements with index i+1 to result.number)
%                            If it equals zero, then there was no
%                            separation.
%
% And MONA will create a banner if plots equals 1.
%
% This function is part of LIBRA: the Matlab Library for Robust Analysis,
% available at:
%              http://wis.kuleuven.be/stat/robust.html
%
% Written by Wai Yan Kong (May 2006)
% Last Revision: 27 March 2009 S.Verboven

% Check whether the number of input arguments is correct
if (nargin<1)
    error('One input argument required (datamatrix)')
elseif (nargin<2)
    plots=0;
elseif (nargin>2)
    error('Too many input arguments')
end

% Define number of observations and variables
[n,p]=size(x);


% Check whether x is a matrix containing only binary values
% and whether x has missing values
% We make a revised matrix xx
missing=zeros(1,p);
for j = 1:p
    for i= 1:n
        if (x(i,j)==0 | x(i,j)==1)
            missing(j)=missing(j);
            xx(i,j)=x(i,j);
        elseif (x(i,j)==2)
            missing(j)=missing(j)+1;
            for k=1:p
                a=0;
                b=0;
                c=0;
                d=0;

                if k~=j
                    if x(i,k) ~= 2

                        for t=1:n
                            if (x(t,j)==1 & x(t,k)==1)
                                a=a+1;
                            elseif (x(t,j)==1 & x(t,k)==0)
                                b=b+1;
                            elseif (x(t,j)==0 & x(t,k)==1)
                                c=c+1;
                            elseif (x(t,j)==0 & x(t,k)==0)
                                d=d+1;
                            end
                        end
                    end
                end
                association(k)=abs(a*d-b*c);
                resinbetween(k)=a*d-b*c;
                [C,I]=max(association);

                if resinbetween(I)>0
                    xx(i,j)=x(i,I);
                elseif resinbetween(I)<0
                    xx(i,j)=1-x(i,I);
                end
            end
        else
            error('inputmatrix must have binary values or value 2 for missing values')
        end
    end
end

TotalMissing=sum(missing);
fprintf(1,'This inputmatrix has %d missing values\n',TotalMissing)

% Check situations where Mona is not applicable
One=0;
for j=1:p
    if missing(j)>=1
        One=One+1;
    end
end
if One==p
    error('each variable has at least one missing value')
end


for j=1:p

    if (missing(j)>= (n/2))
        fprintf(1,'Variable %d has %d missing values\n',j,missing(j))
        error('The number of missing values for some variable equals or is more than half of the number of objects')
    end
    gelijk=0;
    for s=1:n-1
        if xx(s,j)==xx(s+1,j)
            gelijk=gelijk+1;
        end
    end
    if gelijk==n-1
        fprintf(1,'Variable %d has identical values\n',j)
        error('all values are identical for some variable')
    end

end

% We make the rowvector kx by reading the revised matrix xx
% row by row
Lengte=n*p;
kx=zeros(1,Lengte);

for i = 1:n
    for j= 1:p
        kx((i-1)*p+j) = xx(i,j);
    end
end


% Actual calculations
[ner,lava,ban]=monac(n,p,kx);

% We want lava and ban to be vectors of length n-1
lava(1)=[];
ban(1)=[];


% Putting things together
result = struct('matrix',xx,'observations',n,'variables',p,...
    'objectorder',ner,'usedvariable',lava,'separationstep',ban, 'class','MONA');

% Plots
try 
    if plots
        makeplot(result,'classic',0)
    end
catch %output must be given even if plots are interrupted 
    %> delete(gcf) to get rid of the menu 
end




