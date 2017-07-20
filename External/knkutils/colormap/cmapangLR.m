function cmap = cmapangLR(s)

% function cmap = cmapangLR(s)
%
% <s> (optional) is the desired size of the colormap.
%   note that regardless of what <s> is, the returned colormap has 64 entries!
%
% return the colormap.  this colormap has centered circularity!
%
% example:
% figure; drawcolorbarcircular(cmapangLR,1);

% deal with input
if ~exist('s','var') || isempty(s)
  s = 64;
end
if ~isequal(s,64)
  warning('we are forcing the use of 64 colors in the cmapangLR.m colormap!');
  s = 64;
end

% get the base colormap
cmap = cmapang;

% flip
cmap = flipud(circshift(cmap,[31 0]));
