function [xDistSort,yDistSort]=sortPointMinDist(x,y)
%% function [xDistSort,yDistSort]=sortPointMinDist(x,y)
% Sorts arbitrary points into a Clock Wise contour.
%
%% Syntax
% [xDistSort,yDistSort]=sortPointMinDist(x,y)
%
%% Description
% This functions goal is to order points efficintly to allow plotting a contoure with
% them. While this problem can be hard to solve, and even sometimes considered unsolvable,
% it is solved here basing on the assumption that "nearest point" is the nect point. This
% results in a solution of O(N^2) complexity (calculating all distamnces between points),
% but im most cases it will be of significantly lower complexity.
%
%% Input arguments:
% x- x coordinates of the points 
%
% y- x coordinates of the points 
%
%% Output arguments
% xDistSort- sorted points x coordinates. 
%
% yDistSort- sorted points y coordinates. 
%
%% Issues & Comments (None)
% The resulting shape will have points connected,accordung to a predfined metric, so it
% will not always result in a shape user wished for. Add additonal points to fix this
% issue, when needed.
% The funciton is pretty damandig computationally (~20 slower than sortPoint2ContourCW),
% so should be used not too frequently.
%
%% Example
% N=11;
% x=10*rand(1,N);
% y=10*rand(1,N);
% [xCW,yCW]=sortPointMinDist(x,y);
% figure;
% plot(x,y,'.-b');
% hold on;
% plot(xCW,yCW,'.-r','LineWidth',2);
% hold off;
% axis equal;
% title('Sorting arbitrary Points to form a Contour','FontSize',14); 
% legend('Unsorted points contour', 'Sorted points contour');
%
%% See also
% sortPoint2ContourCW;  % Custom function
% mask2poly;            % Custom function
% poly2mask;            % Matlab function
%
%% Revision history
% First version: Nikolay S. 2011-07-24.
% Last update:   Nikolay S. 2011-07-25.
%
% *List of Changes:*
% 

%% convert to column vectors and sort
nPoints=length(x);
iDistSort=zeros(1,nPoints);
distMat=Inf(nPoints,nPoints); % col index- distance from, row index- distance to

for iDistRow=1:nPoints
   ind2=(iDistRow+1):nPoints;
   distMat(iDistRow, ind2)=sqrt((x(ind2)-x(iDistRow)).^2+(y(ind2)-y(iDistRow)).^2);
   % distance between a->b eqauls distance between b->a 
   distMat(ind2, iDistRow)=transpose(distMat(iDistRow, ind2)); 
end

% find pair of closest points- first and second points
[~,pointLinInd] = min(distMat(:));
[iDistSort(1),nextPoint] = ind2sub(size(distMat), pointLinInd);
for iPoint=1:nPoints-1
   currPoint=nextPoint;
   [minDist,nextPoint] = min(distMat(currPoint, :)); % find next point- closest to current
   distMat(currPoint,:)=Inf; % delete distances from current point
   distMat(:,currPoint)=Inf; % delete distances to   current point
   iDistSort(iPoint+1)=nextPoint; % store sorted points indexes
   
   if isinf(minDist) % this will b true in case of an error
      break;
   end
end
xDistSort=x(iDistSort);
yDistSort=y(iDistSort);