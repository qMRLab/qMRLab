function outliers = detect_outliers(X,Y,fig_flag,method)

% Finds univariate and multivariate outliers 
% 3 'methods' are available and they can return different
% results  
%
% FORMAT outliers = detect_outliers(X,Y)
%        outliers = detect_outliers(X,Y,fig_flag,'method')
%
% INPUTS: X and Y are two vectors of the same length.
%         fig_flag 1/0 indicates to make a figure or not
%         method 'boxplot' relies on the interquartile range
%                'MAD' relies on the median absolute deviation to the  median
%                'S-outlier' relies on the median of absolute distances
%                if empty or 'All', the 3 methods are computed
%
% OUTPUTS: outliers is a structure with:
%               
%          * univariate outliers flagged 
%           outliers.univariate = indices of univariate outliers in X
%           outliers.univariate = indices of univariate outliers in Y
%
%          * bivariate outliers flagged 
%           outliers.bivariate = indices of bivariate outliers 
%
% The boxplot rule for univariate outliers uses Carling's modification of 
% the boxplot rule - Carling, K. (2000). Resistant outlier rules and the 
% non-Gaussian case. Statistics & Data analysis, 33, 249-258.
%
% The median absolute deviation standard deviations for univariate outliers
% uses a modification for finite sample size -  William, J Stat Computation 
% and Simulation, 81, 11, 2011
%
% S-outliers relies on the median of absolute distances. Because it doesn't
% rely on an estimator of central tendency (like the MAD) it works well for
% non symmetric distributons - Rousseeuw, P.J. and Croux C. (1993). 
% Alternatives to the the median absolute deviation. Journal of the American 
% Statitical Association, 88 (424) p 1273-1263
%
% Multivariate outliers are detected by computing all the distances to the 
% center of the bivariate cloud (ie using a projection method) and then 
% checking if the distances are above a given distance (Wilcox 2012).
% For 'boxplot' and 'MAD' it corresponds to the median distance +
% gval*value with gval = sqrt(chi2inv(0.975,2)) and value being the IQR or
% the normalized MAD. For 'S-outlier' it is like in the univariate case.
%
% See also MADMEDIANRULE, IQR_METHOD, MCDCOV 
%
% Cyril Pernet, v1 23/07/2012
% Cyril Pernet and Guillaume Rousselet, v2 08/10/2012
% -------------------------------------------------
%  Copyright (C) Corr_toolbox 2012


%% check inputs

if nargin<2 
    error('not enough input arguments');
elseif nargin==2 
    fig_flag = 1;
    method = 'All';
elseif nargin == 3
     method = 'All';   
elseif nargin>4
    error('too many input arguments');
end

% transpose if x or y are not in column
if size(X,1) == 1 && size(X,2) > 1; X = X'; end
if size(Y,1) == 1 && size(Y,2) > 1; Y = Y'; end

if numel(size(X))>2 || numel(size(Y))>2
    error('only taking vectors as input')
end

if numel(X) ~= numel(Y)
    error('vector must be of the same length')
end

[n,p]=size(X);

%% ------------------------------------------------------------------
%% univariate outliers


if strcmp(method,'All') || strcmp(method,'boxplot')
    % Carling's modification of the boxplot rule
    Xoutliers_boxplot = iqr_method(X,2);
    Youtliers_boxplot = iqr_method(Y,2);
    outliers.univariate.boxplot = [Xoutliers_boxplot ,Youtliers_boxplot];
end

if strcmp(method,'All') || strcmp(method,'MAD')
    % applies MAD with a correction for finite sample sizes
    [Xoutliers_MAD,distance] = madmedianrule(X,2);
    [Youtliers_MAD,distance] = madmedianrule(Y,2);
    outliers.univariate.MAD = [Xoutliers_MAD Youtliers_MAD];
end

if strcmp(method,'All') || strcmp(method,'S-outlier')
    [Xoutliers_Soutlier,distance] = madmedianrule(X,3);
    [Youtliers_Soutlier,distance] = madmedianrule(Y,3);
    outliers.univariate.Soutlier = [Xoutliers_Soutlier Youtliers_Soutlier];
end

if strcmp(method,'All')
    outliers.univariate.intersection = zeros(n,2);
    X_all = intersect(intersect(find(Xoutliers_boxplot),find(Xoutliers_MAD)),find(Xoutliers_Soutlier));
    Y_all = intersect(intersect(find(Youtliers_boxplot),find(Youtliers_MAD)),find(Youtliers_Soutlier));
    outliers.univariate.intersection(X_all,1) = 1;
    outliers.univariate.intersection(Y_all,2) = 1;
end

%% ------------------------------------------------------------------
%% multivariate outliers 

tmpX=X; tmpY=Y; X = [X Y];
% get the centre of the bivariate distribution
result=mcdcov(X,'cor',1,'plots',0,'h',floor((n+size(X,2)*2+1)/2));
center = result.center;
flag = NaN(n,3);
gval = sqrt(chi2inv(0.975,2)); 
     
% orthogonal projection to the lines joining the center
% followed by univariate outlier detection 

for i=1:n % for each row
    dis=NaN(n,1);
    B = (X(i,:)-center)';
    BB = B.^2;
    bot = sum(BB);
    if bot~=0
        for j=1:n
            A = (X(j,:)-center)';
            dis(j)= norm(A'*B/bot.*B);
        end
        
        % IQR rule for skipped corr
        [ql,qu]=idealf(dis);
        record1{i} = (dis > median(dis)+gval.*(qu-ql)) ;
        
        % MAD rule for skipped corr
        [out,value] = madmedianrule(dis,2);
        record2{i} = dis > (median(dis)+gval.*value);        
        
        % S-outlier
        [record3{i},value] = madmedianrule(dis,3);
    end
end

flag(:,1) = sum(cell2mat(record1),2); % if any point is flagged
flag(:,2) = sum(cell2mat(record2),2); 
flag(:,3) = sum(cell2mat(record3),2); 
flag=(flag>=1);
vec=repmat([1:n]',1,8);
for m=1:3
    if sum(flag(:,m))==0
        outid{m}=[];
    else
        outid{m} = vec(flag(:,m),m);
    end
end

vec = zeros(n,1);
if strcmp(method,'All') || strcmp(method,'boxplot')
    outliers.bivariate.boxplot = vec;
    outliers.bivariate.boxplot(outid{1}) = 1;
end

if strcmp(method,'All') || strcmp(method,'MAD')
    outliers.bivariate.MAD = vec;
    outliers.bivariate.MAD(outid{2}) = 1;
end

if strcmp(method,'All') || strcmp(method,'S-outlier')
    outliers.bivariate.Soutlier = vec;
    outliers.bivariate.Soutlier(outid{3}) = 1;
end

if strcmp(method,'All')
    outliers.bivariate.intersection = vec;
    outliers.bivariate.intersection(intersect(intersect(outid{1},outid{2}),outid{3})) = 1;
end



%% ------------------------------------------------------------------  
%% figure(s)

if strcmp(method,'All') || strcmp(method,'boxplot')
    figure('Color','w','Name','Outlier detection using the boxplot rule');
    make_figure(X(:,1),X(:,2),outliers.univariate.boxplot,outliers.bivariate.boxplot);
end

if strcmp(method,'All') || strcmp(method,'MAD')
    figure('Color','w','Name','Outlier detection using the MAD');
    make_figure(X(:,1),X(:,2),outliers.univariate.MAD,outliers.bivariate.MAD);
end

if strcmp(method,'All') || strcmp(method,'S-outlier')
    figure('Color','w','Name','Outlier detection using S-estimator');
    make_figure(X(:,1),X(:,2),outliers.univariate.Soutlier,outliers.bivariate.Soutlier);
end

end

function make_figure(X,Y,Univariate_out,Bivariate_out)
% routine to make the figure
 
% univariate subplot
subplot(1,2,1); 
scatter(X,Y,99,'o','filled'); grid on; hold on
xlabel('X','Fontsize',12); ylabel('Y','Fontsize',12);
title('Univariate outliers','Fontsize',16);
if sum(Univariate_out(:)) > 0
    Xoutliers = Univariate_out(:,1);
    Youtliers = Univariate_out(:,2);
    common = intersect(find(Xoutliers),find(Youtliers));
    if ~isempty(common)
        scatter(X(common),Y(common),100,'k','filled')
        try common ~= find(Xoutliers)
            scatter(X(find(Xoutliers)),Y(find(Youtliers)),100,'r','filled')
            scatter(X(find(Youtliers)),Y(find(Youtliers)),100,'g','filled')
            legend('data','outliers in X','outliers in Y','outliers in X and in Y')
        catch ME
            legend('data','outliers in X and in Y')
        end
    
    elseif ~isempty(find(Xoutliers)) && ~isempty(find(Youtliers))
        scatter(X(find(Xoutliers)),Y(find(Xoutliers)),100,'r','filled')
        scatter(X(find(Youtliers)),Y(find(Youtliers)),100,'g','filled')
        legend('data','outliers in X','outliers in Y');
    
    elseif ~isempty(find(Xoutliers)) && isempty(find(Youtliers))
        scatter(X(find(Xoutliers)),Y(find(Xoutliers)),100,'r','filled')
        legend('data','outliers in X')
    
    elseif ~isempty(find(Youtliers)) && isempty(find(Xoutliers))
        scatter(X(find(Youtliers)),Y(find(Youtliers)),100,'g','filled')
        legend('data','outliers in Y')
    end
    disp(' ');
    fprintf('%g outliers found in X \n',sum(Xoutliers))
    fprintf('%g outliers found in Y \n',sum(Youtliers))
end
axis tight
box on;set(gca,'FontSize',14)

% bivariate outliers
subplot(1,2,2); 
a = X(find(Bivariate_out==0));
b = Y(find(Bivariate_out==0));
scatter(a,b,100,'b','fill');
grid on; hold on;
hh = lsline; set(hh,'Color','r','LineWidth',4);
scatter(X(find(Bivariate_out)),Y(find(Bivariate_out)),100,'r','filled')
xlabel('X','Fontsize',12); ylabel('Y','Fontsize',12);
title('Bivariate outliers','Fontsize',16);
fprintf('%g bivartiate outliers found \n',sum(Bivariate_out))
axis([min(X) max(X) min(Y) max(Y)])
box on;set(gca,'FontSize',14)
end
