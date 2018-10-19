function silhouetteplot(sylinf,n,class)

%SILHOUETTEPLOT creates a silhouetteplot for output of the cluster
% algorithms pam or fanny.
%
% I/O: silhouetteplot(sylinf,n)
%
% This function is part of LIBRA: the Matlab Library for Robust Analysis,
% available at:  
%              http://wis.kuleuven.be/stat/robust.html
%
% Last update: 13/02/2009


Y=sylinf(:,3);
% we calculate b= "Y but with a bar with length zero if the objects
% are from another cluster"
% and h= "objects but with a 0 between 2 clusters" = "g with a 0 if
% it is a sparse between 2 clusters"

g=sylinf(:,4); %original objectnumbers
f=sylinf(:,1)-1;
for j=1:n
    b(j+f(j))=Y(j);
    h(j+f(j))=g(j);
end
b1=flipdim(b,2);
h1=flipdim(h,2);
% we use this b1 and h1 to plot the barh (instead of Y and g)
barh(b1,1);
title(['Silhouette Plot obtained with ',class,' clustering']) ;
xlabel('Silhouette width');
YT=1:n+(sylinf(n,1)-1);
set(gca,'YTick',YT);
set(gca,'YTickLabel',h1);
axis([min([Y' 0]),max([Y' 0]),0.5,n+0.5+f(n)]);
