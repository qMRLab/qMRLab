function corr_normplot(x,y)

% Plots univariate histograms, scatterplot, and joint histogram
% for the bivariate data set defined by [x,y] 
%
% FORMAT: corr_normplot(x,y)
%
% INPUTS: x and y are two vectors of the same length

% Cyril Pernet v1 20/06/2012
% -----------------------------
% Copyright (C) Corr_toolbox 2012

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


figure('Name','Histograms and scatter plot')
set(gcf,'Color','w');

% 1st univariate histogram
subplot(3,5,2:3);
[nu,x1,h1,xp,yp]=univar(x); 
bar(x1,nu/(length(x)*h1),1,'FaceColor',[0.5 0.5 1]);
v = max(yp) + 0.02*max(yp);
grid on; axis([min(x)-1/10*min(x) max(x)+1/10*max(x) 0 v]); hold on
plot(xp,yp,'r','LineWidth',3); title('Density histogram for X','Fontsize',16); 
ylabel('Freq.','FontSize',14); xlabel('X.','FontSize',14)
box on;set(gca,'FontSize',14)

% 2nd univariate histogram
subplot(3,5,[6 11]);
[nu,x2,h2,xp,yp]=univar(y);
bar(x2,nu/(length(y)*h2),1,'FaceColor',[0.5 0.5 1]);
v = max(yp) + 0.02*max(yp);
grid on; axis([min(y)-1/10*min(y) max(y)+1/10*max(y) 0 v]); hold on
plot(xp,yp,'r','LineWidth',3); view(-90,90) 
title('Density histogram for Y','Fontsize',16); 
ylabel('Freq.','FontSize',14); xlabel('Y.','FontSize',14);
box on;set(gca,'FontSize',14)
drawnow

% scatter plot
subplot(3,5,[7 8 12 13]);
scatter(x,y,100,'filled'); grid on
xlabel('x','Fontsize',14); ylabel('y','Fontsize',14);
axis([min(x)-1/10*min(x) max(x)+1/10*max(x) min(y)-1/10*min(y) max(y)+1/10*max(y)])
title('Scatter plot','Fontsize',16);
box on;set(gca,'FontSize',14,'Layer','Top')
drawnow

% joint histogram
subplot(3,5,[9 10 14 15]);
k = round(1 + log2(length(x)));
hist3([x y],[k k],'FaceAlpha',.65);
xlabel('X','FontSize',14); ylabel('Y','FontSize',14); title('Bivariate histogram','Fontsize',16)
set(gcf,'renderer','opengl');
set(gca,'FontSize',14)
drawnow
try
    set(get(gca,'child'),'FaceColor','interp','CDataMode','auto');
end



