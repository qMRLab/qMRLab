function f = cmapsign4(n)

% function f = cmapsign4(n)
%
% <n> (optional) is desired number of entries
%   default: 64
%
% return a cyan-blue-black-red-yellow colormap.
% suitable for ranges like [-X X].
%
% example:
% figure; imagesc(rand(100,100)); axis equal tight; colormap(cmapsign4); colorbar;

% inputs
if ~exist('n','var') || isempty(n)
  n = 64;
end

% constants
colors = [
  .8 1 1 % cyan-white
  0 1 1  % cyan
  0 0 1  % blue
  0 0 0  % black
  1 0 0  % red
  1 1 0  % yellow
  1 1 .8 % yellow-white
  ];

% do it (MAYBE CONSOLIDATE THIS CODE?)
f = [];
for p=1:size(colors,2)
  f(:,p) = interp1(linspace(0,1,size(colors,1)),colors(:,p)',linspace(0,1,n),'linear');
end


% OLD
% f = colorinterpolate(colors,31,1);
