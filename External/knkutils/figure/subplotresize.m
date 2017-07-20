function subplotresize(r,c,widthfrac,heightfrac,fig)

% function subplotresize(r,c,widthfrac,heightfrac,fig)
%
% <r> is the number of rows
% <c> is the number of cols
% <widthfrac> (optional) is the fraction for a subplot to occupy
%   in the width direction (left-right).  if [] or not supplied,
%   default to .95.
% <heightfrac> (optional) is the fraction for a subplot to occupy
%   in the height direction (up-down).  if [] or not supplied,
%   default to .95.
% <fig> (optional) is the figure number to apply to.  if []
%   or not supplied, default to gcf.
%
% modify the 'Position' property of each of the subplot axes
% that belong to figure <fig>.
%
% example:
% figure;
% subplotresize(2,3);

% deal with inputs
if ~exist('widthfrac','var') || isempty(widthfrac)
  widthfrac = .95;
end
if ~exist('heightfrac','var') || isempty(heightfrac)
  heightfrac = .95;
end
if ~exist('fig','var') || isempty(fig)
  fig = gcf;
end

% do it
for p=1:r*c
  subplot(r,c,p);
  xoffset = (1/c)*(mod2(p,c)-1);
  yoffset = (1/r)*(r-ceil(p/c));
  xextra = (1/c)*((1-widthfrac)/2);
  yextra = (1/r)*((1-heightfrac)/2);
  cwidth = (1/c)*widthfrac;
  cheight = (1/r)*heightfrac;
  set(gca,'Position',[xoffset+xextra yoffset+yextra cwidth cheight]);
end
