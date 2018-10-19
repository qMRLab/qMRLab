function density = joint_density(x,y,flag)

% simple routine to compute and plot the joint density histogram of x and y
% 
% FORMAT: joint_density(x,y)
%         joint_density(x,y,flag)
%
% INPUTS: x and y are two vectors of the same length
%         flag if 1 (default) plot both the mesh and isocontour else only plot isocontrour 

% Ref: Martinez, W.L. & Martinez, A.R. 2008.
% Computational Statistics Handbook with Matlab. 2nd Ed. 

% Cyril Pernet v2 23/07/2012 
% -----------------------------
% Copyright (C) Corr_toolbox 2012

if nargin == 2
    flag = 1;
end

if size(x)~=size(y)
    error('X and Y must have the same size')
end

[r c] = size(x);
if r == 1 && c > 1
    x = x'; 
    y = y';
elseif r > 1 && c > 1
    error('X and Y must be 2 vectors, more than 1 column/row detected')
end


n = length(x); 
% nb of bins
k = round(1 + log2(n));
% bin sizes
[nu,p]=hist(x,k); h1 = p(2) - p(1);
[nu,p]=hist(y,k); h2 = p(2) - p(1);
% start binning at
bin0 = [floor(min(x)) floor(min(y))];
% make a mesh
t1 = bin0(1):h1:(h1*k+bin0(1));
t2 = bin0(2):h2:(h2*k+bin0(2));
[X,Y]=meshgrid(t1,t2);
% frequency per bin in the mesh
[nr,nc]=size(X);
vu = zeros(nr-1,nc-1);
for i=1:size(vu,1)
    for j=1:size(vu,2)
        xv = [X(i,j) X(i,j+1) X(i+1,j+1) X(i+1,j)];
        yv = [Y(i,j) Y(i,j+1) Y(i+1,j+1) Y(i+1,j)]; % coordinates
        in = inpolygon(x,y,xv,yv); % which data in the box
        vu(i,j) = sum(in(:)); % count
    end
end
pdf = vu./(n*h1*h2); % normalize
 
% plot
if flag == 1
    figure('Name','Joint density pdf'); set(gcf,'Color','w');
    subplot(1,2,1);
    surfl(pdf-0.01); axis tight ; xlabel('X','FontSize',14);
    ylabel('Y','FontSize',14); zlabel('density','FontSize',14);
    title('Joint density histogram','Fontsize',16); set(gcf,'renderer','opengl');
    set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
    set(gca,'FontSize',14,'Layer','Top')
    axis square
    
    subplot(1,2,2);
else
    figure('Name','Isocontour of the joint pdf'); set(gcf,'Color','w');
end
contourf(pdf); axis tight ; xlabel('X','FontSize',14);
ylabel('Y','FontSize',14);
title('Isocontour of the joint density','Fontsize',16);
set(gca,'FontSize',14,'Layer','Top')
axis square

if nargout > 0
    density = pdf;
end
