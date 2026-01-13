% rfv = verse(gv,rf)
%
% Computes the versed version of rf for a given time-vayring gradient gv

%  written by John Pauly, 1992
%  (c) Board of Trustees, Leland Stanford Junior University

function rfv = verse(g,rf)

[m n] = size(g);
if m<n, g = g.'; end;
[m n] = size(rf);
if m<n,
  rf = conj(rf');
  [m n] = size(rf);
end;
k = cumsum(g);
k = (m-1)*k/max(k);
rfv = [];
g = m*g/sum(g);
for j=1:n,
  rft = g.*interp1([1:m],rf(:,j),k,'spline');
  rfv = [rfv rft];
end;
