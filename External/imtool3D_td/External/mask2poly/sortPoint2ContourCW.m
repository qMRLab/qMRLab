function [xCW,yCW]=sortPoint2ContourCW(x,y)
%% function [xCW,yCW]=sortPoint2ContourCW(x,y)
% Sorts arbitrary points into a Clock Wise direction contour.
%
%% Syntax
% [xCW,yCW]=sortPoint2ContourCW(x,y)
%
%% Description
% This functions goal is to order points in a clockwise order efficintly. While this
% problem can be hard to solve, and even sometimes considered unsolvable, it is solved
% here basing on the assumption that "nearest point in Clock Wise direction" is the point
% found after sorting by X values, and finding nearest point in Y. This results in a
% solution of O(N^2) complexity, but im most cases it will be of significantly lower
% complexity.
%
%% Input arguments:
% x- x coordinates of the points 
%
% y- x coordinates of the points 
%
%% Output arguments
% xCW- sorted points (so a CW contour will be created) x coordinates. 
%
% yCW- sorted points (so a CW contour will be created) y coordinates. 
%
%% Issues & Comments (None)
% The resulting shape will have points connected,accordung to a predfined metric, so it
% will not always result in a shape user wished for. Add additonal points to fix this
% issue, when needed.
% To avoid "saw toothe coming from neighbouring poinst, comment out the while loop lines
% 77-86. This will also improve run time, but will be less accurate.
%
%% Example
% N=11;
% x=10*rand(1,N);
% y=10*rand(1,N);
% [xCW,yCW]=sortPoint2ContourCW(x,y);
% figure;
% plot(x,y,'.-b');
% hold on;
% plot(xCW,yCW,'.-r','LineWidth',2);
% hold off;
% title('Sorting arbitrary Points into Clock Wise Contour','FontSize',14); 
% legend('Unsorted points contour', 'Sorted points contour');
%
%% See also
% poly2mask;	% Matlab function
% convhull;    % Matlab function
% mask2poly;   % Custom function
%
%% Revision history
% First version: Nikolay S. 2011-07-14.
% Last update:   Nikolay S. 2011-07-17.
%
% *List of Changes:*
% - Sort is performed only if x is unsorted.

%% convert to column vectors and sort
x=x(:);
y=y(:);

if ~issorted(x)
   [x,ix]=sort(x);
   y=y(ix);
end

% as we have sorted inputs for ascending X values, so we will work on Y in order to achive
% Clock Wise contour
%% Initial points attribution
diffY=diff(cat(1,y(1),y));
isIncY=diffY>1;         % find points where Y values Increase by more than 1
isNeigh=abs(diffY)<=1;  % find points where Y values change by 1/0- neighbouring points
isDecY=diffY<-1;        % find points where Y values Decrease by more than 1
isUndeterminedY=~(isIncY|isDecY); % find poits not set to be Increasing or Decreasing

%% Determine each point to be either Increasing or Decreasing
while sum(double(isUndeterminedY))>2       
   % a point is Increasing if it is a neigbour of an Increasing point
   isIncreasingNeig=isNeigh&circshift(isIncY,+1); 
   isIncY=isIncY|isIncreasingNeig;

   % a point is Decreasing if it is a neigbour of an Decreasing point
   isDecNeig=isNeigh&circshift(isDecY,+1);
   isDecY=isDecY|isDecNeig;
   isUndeterminedY=~(isIncY|isDecY);
end

xCW=cat(1,x(isIncY),flipud(x(isDecY)));
yCW=cat(1,y(isIncY),flipud(y(isDecY)));