function [r,t,h,outid,hboot,CI]=skipped_correlation(x,y,fig_flag)

% performs a robust correlation using pearson/spearman correlation on
% data cleaned up for bivariate outliers - that is after finding the
% central point in the distribution using the mid covariance determinant,
% orthogonal distances are computed to this point, and any data outside the
% bound defined by the idealf estimator of the interquartile range is removed.
% 
% FORMAT:
%          [r,t,h] = skipped_correlation(X);
%          [r,t,h] = skipped_correlation(X,fig_flag);
%          [r,t,h,outid,hboot,CI] = skipped_correlation(X,Y,fig_flag);
%
% INPUTS:  X is a matrix and corelations between all pairs (default) are computed
%          pairs (optional) is a n*2 matrix of pairs of column to correlate  
%          fig_flag (optional, ( by default) indicates to plot the data or not
%
% OUTPUTS:
%          r is the pearson/spearman correlation 
%          t is the T value associated to the skipped correlation
%          h is the hypothesis of no association at alpha = 5% 
%          outid is the index of bivariate outliers
% 
%          optional:
%
%          hboot 1/0 declares the test significant based on CI (h depends on t)
%          CI is the robust confidence interval computed by bootstrapping the 
%          cleaned-up data set and taking the .95 centile values
%
% This code rely on the mid covariance determinant as implemented in LIBRA
% - Verboven, S., Hubert, M. (2005), LIBRA: a MATLAB Library for Robust Analysis,
% Chemometrics and Intelligent Laboratory Systems, 75, 127-136.
% - Rousseeuw, P.J. (1984), "Least Median of Squares Regression,"
% Journal of the American Statistical Association, Vol. 79, pp. 871-881.
% 
% The quantile of observations whose covariance is minimized is 
% floor((n+size(X,2)*2+1)/2)),
% i.e. ((number of observations + number of variables*2)+1) / 2, 
% thus for a correlation this is floor(n/2 + 5/2).
%
% See also MCDCOV, IDEALF.

% Cyril Pernet & Guillaume Rousselet, v1 - April 2012
% ---------------------------------------------------
%  Copyright (C) Corr_toolbox 2012

%% data check

if nargin <2 
    error('not enough input arguments');
elseif nargin == 2
    fig_flag = 1;
elseif nargin > 3
    error('too many input arguments');
end

% transpose if x or y are not in column
if size(x,1) == 1 && size(x,2) > 1; x = x'; end
if size(y,1) == 1 && size(y,2) > 1; y = y'; end

% if X a vector and Y a matrix, 
% repmat X to perform multiple tests on Y (or the other around)

% the default hypothesis is to test that all pairs of correlations are 0
hypothesis = 1;  

% now if x is a vector and we test multiple y (or the other way around) one
% has to adjust for this
if size(x,2) == 1 && size(y,2) > 1
    x = repmat(x,1,size(y,2));
    hypothesis = 2;
elseif size(y,2) == 1 && size(x,2) > 1
    y = repmat(y,1,size(x,2));
    hypothesis = 2;
end

[n,p] = size(x);
if size(x) ~= size(y)
    error('x and y are of different sizes')
elseif n < 10
    error('robust effects can''t be computed with less than 10 observations')
elseif n > 200 && p < 10
    warndlg('robust correlation and T value will be computed, but h is not validated for n>200')
elseif p > 10
    warndlg('the familly wise error correction for skipped correlation is not available for more than 10 correlations')
end

gval = sqrt(chi2inv(0.975,2)); % in fact depends on size(X,2) but here always = 2

%% compute
for column = 1:p
    if p>1
        fprintf('skipped correlation: processing pair %g \n',column); 
    end
    
    X = [x(:,column) y(:,column)];
    % flag bivariate outliers
    flag = bivariate_outliers(X);
    % remove outliers
    vec=1:n;           
    if sum(flag)==0
        outid{column}=[];
    else
        flag=(flag>=1);
        outid{column}=vec(flag);
    end
    keep=vec(~flag);
    
    %% Pearson/Spearman correlation
    
    if  p == 1 % in the special case of a single test Pearson is valid too
        a{column} = x(keep);
        b{column} = y(keep);
        
        rp = sum(detrend(a{column},'constant').*detrend(b{column},'constant')) ./ ...
            (sum(detrend(a{column},'constant').^2).*sum(detrend(b{column},'constant').^2)).^(1/2);
        tp = rp*sqrt((n-2)/(1-rp.^2));
        r.Pearson = rp; t.Pearson = tp;
        
        xrank = tiedrank(a{column},0); yrank = tiedrank(b{column},0);
        rs = sum(detrend(xrank,'constant').*detrend(yrank,'constant')) ./ ...
            (sum(detrend(xrank,'constant').^2).*sum(detrend(yrank,'constant').^2)).^(1/2);
        ts = rs*sqrt((n-2)/(1-rs.^2));
        r.Spearman = rs; t.Spearman = ts;
    
    else % multiple tests, only use Spearman to control type 1 error
        a{column} = x(keep,column); xrank = tiedrank(a{column},0); 
        b{column} = y(keep,column); yrank = tiedrank(b{column},0);
        r(column) = sum(detrend(xrank,'constant').*detrend(yrank,'constant')) ./ ...
            (sum(detrend(xrank,'constant').^2).*sum(detrend(yrank,'constant').^2)).^(1/2);
        t(column) = r(column)*sqrt((n-2)/(1-r(column).^2));
    end
end

%% get h

% the default test of 0 correlation is for alpha = 5%

c = 6.947 / n + 2.3197; % valid for n between 10 and 200
if p == 1
    h.Pearson = abs(tp) >= c;
    h.Spearman = abs(ts) >= c;
else
    h= abs(t) >= c;
end

%% adjustement for multiple testing using the .95 quantile of Tmax
if p>1 && p<=10
    switch hypothesis
        
        case 1 % Hypothesis of 0 correlation between all pairs
            
            if p == 2;  q = 5.333*n^-1 + 2.374;    end
            if p == 3;  q = 8.8*n^-1 + 2.78;       end
            if p == 4;  q = 25.67*n^-1.2 + 3.03;   end
            if p == 5;  q = 32.83*n^-1.2 + 3.208;  end
            if p == 6;  q = 51.53*n^-1.3 + 3.372;  end
            if p == 7;  q = 75.02*n^-1.4 + 3.502;  end
            if p == 8;  q = 111.34*n^-1.5 + 3.722; end
            if p == 9;  q = 123.16*n^-1.5 + 3.825; end
            if p == 10; q = 126.72*n^-1.5 + 3.943; end
            
        case 2 % Hypothesis of 0 correlation between x1 and all y
            
            if p == 2;  q = 5.333*n^-1 + 2.374;   end
            if p == 3;  q = 8.811*n^-1 + 2.54;    end
            if p == 4;  q = 14.89*n^-1.2 + 2.666; end
            if p == 5;  q = 20.59*n^-1.2 + 2.920; end
            if p == 6;  q = 51.01*n^-1.5 + 2.999; end
            if p == 7;  q = 52.15*n^-1.5 + 3.097; end
            if p == 8;  q = 59.13*n^-1.5 + 3.258; end
            if p == 9;  q = 64.93*n^-1.5 + 3.286; end
            if p == 10; q = 58.5*n^-1.5 + 3.414;  end
    end
    
   h = abs(t) >= q; 
end


%% bootstrap
if nargout > 4
    
    [n,p]=size(a);
    nboot = 1000;
    level = 5/100;
    if p > 1
        level = level / p;
    end
    low = round((level*nboot)/2);
    if low == 0
        error('adjusted CI cannot be computed, too many tests for the number of observations')
    else
        high = nboot - low;
    end
    
    for column = 1:p
        % here different resampling because length(a) changes
        table = randi(length(a{column}),length(a{column}),nboot);
        
        for B=1:nboot
            % do Spearman
            tmp1 = a{column}; xrank = tiedrank(tmp1(table(:,B)),0);
            tmp2 = b{column}; yrank = tiedrank(tmp2(table(:,B)),0);
            rsb(B,column) = sum(detrend(xrank,'constant').*detrend(yrank,'constant')) ./ ...
                (sum(detrend(xrank,'constant').^2).*sum(detrend(yrank,'constant').^2)).^(1/2);
            % get regression lines for Spearman
            coef = pinv([xrank ones(length(a{column}),1)])*yrank;
            sslope(B,column) = coef(1); sintercept(B,column) = coef(2,:);
            
            if p == 1 % ie only 1 correlation thus Pearson is good too
                rpb(B,column) = sum(detrend(tmp1(table(:,B)),'constant').*detrend(tmp2(table(:,B)),'constant')) ./ ...
                    (sum(detrend(tmp1(table(:,B)),'constant').^2).*sum(detrend(tmp2(table(:,B)),'constant').^2)).^(1/2);
                coef = pinv([tmp1(table(:,B)) ones(length(a{column}),1)])*tmp2(table(:,B));
                pslope(B,column) = coef(1); pintercept(B,column) = coef(2,:);
            end
        end
    end
    
    % in all cases get CI for Spearman
    rsb = sort(rsb,1);
    sslope = sort(sslope,1);
    sintercept = sort(sintercept,1);
    
    % CI and h
    adj_nboot = nboot - sum(isnan(rsb));
    adj_low = round((level*adj_nboot)/2);
    adj_high = adj_nboot - adj_low;
    
    for c=1:p
        if adj_low(c) > 0
            CI(:,c) = [rsb(adj_low(c),c) ; rsb(adj_high(c),c)];
            hboot(c) = (rsb(adj_low(c),c) > 0) + (rsb(adj_high(c),c) < 0);
            CIsslope(:,c) = [sslope(adj_low(c),c) ; sslope(adj_high(c),c)];
            CIsintercept(:,c) = [sintercept(adj_low(c),c) ; sintercept(adj_high(c),c)];
        else
            CI(:,c) = [NaN NaN]';
            hboot(c) = NaN;
            CIsslope(:,c) = NaN;
            CIsintercept(:,c) = NaN;
        end
    end
    
    CIpslope = CIsslope; % used in plot - unless only one corr was computed
    
    % case only one correlation
    if p == 1
        rpb = sort(rpb,1);
        pslope = sort(pslope,1);
        pintercept = sort(pintercept,1);
        
        % CI and h
        adj_nboot = nboot - sum(isnan(rpb));
        adj_low = round((level*adj_nboot)/2);
        adj_high = adj_nboot - adj_low;
        
        if adj_low>0
            CIp = [rpb(adj_low) ; rpb(adj_high)];
            hbootp(c) = (rpb(adj_low) > 0) + (rpb(adj_high) < 0);
            CIpslope(:,c) = [pslope(adj_low) ; pslope(adj_high)];
            CIpintercept(:,c) = [pintercept(adj_low) ; pintercept(adj_high)];
        else
            CIp = [NaN NaN];
            hbootp(c) = NaN;
            CIpslope(:,c) = NaN;
            CIpintercept(:,c) = NaN;
        end
        
        % update outputs
        tmp = hboot; clear hboot;
        hboot.Spearman = tmp;
        hboot.Pearson = hbootp;
        
        tmp = CI; clear CI
        CI.Spearman = tmp';
        CI.Pearson = CIp';
    end
end
    
%% plot
if fig_flag ~= 0
    answer = [];
    if p > 1
        answer = questdlg(['plots all ' num2str(p) ' correlations'],'Plotting option','yes','no','yes');
    else
        if fig_flag == 1
            figure('Name','Skipped correlation');
            set(gcf,'Color','w');
        end
        
        if nargout>4
            if ~isnan(r.Pearson); subplot(1,3,1); end
            M = sprintf('Skipped correlation \n Pearson r=%g CI=[%g %g] \n Spearman r=%g CI=[%g %g]',r.Pearson,CI.Pearson(1),CI.Pearson(2),r.Spearman,CI.Spearman(1),CI.Spearman(2));
        else
            M = sprintf('Skipped correlation \n Pearson r=%g h=%g \n Spearman r=%g h=%g',r.Pearson,h.Pearson,r.Spearman,h.Spearman);
        end
        
        scatter(a{1},b{1},100,'b','fill');
        grid on; hold on;
        hh = lsline; set(hh,'Color','r','LineWidth',4);
        try
            [XEmin, YEmin] = ellipse(a{column},b{column});
            plot(real(XEmin), real(YEmin),'LineWidth',2);
            MM = [min(XEmin) max(XEmin) min(YEmin) max(YEmin)];
        catch ME
            text(min(x)+0.01*(min(x)),max(y),'no ellipse found','Fontsize',12)
            MM = [];
        end
        xlabel('X','Fontsize',12); ylabel('Y','Fontsize',12);
        title(M,'Fontsize',16);
        
        % add outliers and scale axis
        scatter(x(outid{1}),y(outid{1}),100,'r','filled');
        MM2 = [min(x) max(x) min(y) max(y)];
        if isempty(MM); MM = MM2; end
        A = floor(min([MM(:,1);MM2(:,1)]) - min([MM(:,1);MM2(:,1)])*0.01);
        B = ceil(max([MM(:,2);MM2(:,2)]) + max([MM(:,2);MM2(:,2)])*0.01);
        C = floor(min([MM(:,3);MM2(:,3)]) - min([MM(:,3);MM2(:,3)])*0.01);
        D = ceil(max([MM(:,4);MM2(:,4)]) + max([MM(:,4);MM2(:,4)])*0.01);
        axis([A B C D]);
        box on;set(gca,'Fontsize',14)
        
        if nargout>4 && sum(~isnan(CIpslope))==2
            % add CI
            y1 = refline(CIpslope(1),CIpintercept(1)); set(y1,'Color','r');
            y2 = refline(CIpslope(2),CIpintercept(2)); set(y2,'Color','r');
            y1 = get(y1); y2 = get(y2);
            xpoints=[[y1.XData(1):y1.XData(2)],[y2.XData(2):-1:y2.XData(1)]];
            step1 = y1.YData(2)-y1.YData(1); step1 = step1 / (y1.XData(2)-y1.XData(1));
            step2 = y2.YData(2)-y2.YData(1); step2 = step2 / (y2.XData(2)-y2.XData(1));
            filled=[[y1.YData(1):step1:y1.YData(2)],[y2.YData(2):-step2:y2.YData(1)]];
            hold on; fillhandle=fill(xpoints,filled,[1 0 0]);
            set(fillhandle,'EdgeColor',[1 0 0],'FaceAlpha',0.2,'EdgeAlpha',0.8);%set edge color
            
            % add histograms of bootstrap
            subplot(1,3,2); k = round(1 + log2(length(rpb))); hist(rpb,k); grid on;
            mytitle = sprintf('Bootstrapped \n Pearsons'' corr h=%g', hboot.Pearson);
            title(mytitle,'FontSize',16); hold on
            xlabel('boot correlations','FontSize',14);ylabel('frequency','FontSize',14)
            plot(repmat(CI.Pearson(1),max(hist(rpb,k)),1),[1:max(hist(rpb,k))],'r','LineWidth',4);
            plot(repmat(CI.Pearson(2),max(hist(rpb,k)),1),[1:max(hist(rpb,k))],'r','LineWidth',4);
            axis tight; colormap([.4 .4 1])
            box on;set(gca,'Fontsize',14)
            
            subplot(1,3,3); k = round(1 + log2(length(rsb))); hist(rsb,k); grid on;
            mytitle = sprintf('Bootstrapped \n Spearmans'' corr h=%g', hboot.Spearman); 
            title(mytitle,'FontSize',16); hold on
            xlabel('boot correlations','FontSize',14);ylabel('frequency','FontSize',14)
            plot(repmat(CI.Spearman(1),max(hist(rsb,k)),1),[1:max(hist(rsb,k))],'r','LineWidth',4);
            plot(repmat(CI.Spearman(2),max(hist(rsb,k)),1),[1:max(hist(rsb,k))],'r','LineWidth',4);
            axis tight; colormap([.4 .4 1])
            box on;set(gca,'Fontsize',14)
        end
    end
    
    
    if strcmp(answer,'yes')
        for f = 1:p
            if fig_flag == 1
                figure('Name',[num2str(f) ' Skipped correlation'])
                set(gcf,'Color','w');
            end
            
            if nargout >4
                if ~isnan(r(f)); subplot(1,3,1); index = 3; else subplot(1,2,1); index = 2; end
                M = sprintf('Spearman skipped correlation r=%g \n %g%%CI [%g %g]',r(f),(1-level)*100,CI(1,f),CI(2,f));
            else
                subplot(1,2,1); index = 2;
                M = sprintf('Spearman skipped correlation \n r=%g h=%g',r(f),h(f));
            end
            
            % plot data with outliers identified
            scatter(a{f},b{f},100,'b','fill');
            grid on; hold on;
            hh = lsline; set(hh,'Color','r','LineWidth',4);
            try
                [XEmin, YEmin] = ellipse(a{f},b{f});
                plot(XEmin, YEmin,'LineWidth',2);
                MM = [min(XEmin) max(XEmin) min(YEmin) max(YEmin)];
            catch ME
                text(min(a{f})+0.01*(min(a{f})),max(b{f}),'no ellipse found','Fontsize',12)
                MM = [];
            end
            xlabel('X','Fontsize',12); ylabel('Y','Fontsize',12);
            title('Outlier detection','Fontsize',16);
            
            % add outliers and scale axis
            scatter(x(outid{f},f),y(outid{f},f),100,'r','filled');
            MM2 = [min(x(:,f)) max(x(:,f)) min(y(:,f)) max(y(:,f))];
            if isempty(MM); MM = MM2; end
            A = floor(min([MM(:,1);MM2(:,1)]) - min([MM(:,1);MM2(:,1)])*0.01);
            B = ceil(max([MM(:,2);MM2(:,2)]) + max([MM(:,2);MM2(:,2)])*0.01);
            C = floor(min([MM(:,3);MM2(:,3)]) - min([MM(:,3);MM2(:,3)])*0.01);
            D = ceil(max([MM(:,4);MM2(:,4)]) + max([MM(:,4);MM2(:,4)])*0.01);
            axis([A B C D]);
            box on;set(gca,'Fontsize',14)
            
            % plot the rank and Spearman
            subplot(1,index,2);
            xrank = tiedrank(a{f},0);
            yrank = tiedrank(b{f},0);
            scatter(xrank,yrank,100,'b','fill'); grid on; hold on
            hh = lsline; set(hh,'Color','r','LineWidth',4); axis tight
            xlabel('X rank','Fontsize',12); ylabel('Y rank','Fontsize',12);
            title(M,'Fontsize',16);
            box on;set(gca,'Fontsize',14)
            
            if nargout>4 && sum(isnan(CIpslope(:,f))) == 0
                % add CI
                y1 = refline(CIsslope(1,f),CIsintercept(1,f)); set(y1,'Color','r');
                y2 = refline(CIsslope(2,f),CIsintercept(2,f)); set(y2,'Color','r');
                y1 = get(y1); y2 = get(y2);
                xpoints=[[y1.XData(1):y1.XData(2)],[y2.XData(2):-1:y2.XData(1)]];
                step1 = y1.YData(2)-y1.YData(1); step1 = step1 / (y1.XData(2)-y1.XData(1));
                step2 = y2.YData(2)-y2.YData(1); step2 = step2 / (y2.XData(2)-y2.XData(1));
                filled=[[y1.YData(1):step1:y1.YData(2)],[y2.YData(2):-step2:y2.YData(1)]];
                hold on; fillhandle=fill(xpoints,filled,[1 0 0]);
                set(fillhandle,'EdgeColor',[1 0 0],'FaceAlpha',0.2,'EdgeAlpha',0.8);%set edge color
                
                % add histograms of bootstrap
                subplot(1,3,3); k = round(1 + log2(length(rsb(:,f)))); hist(rsb(:,f),k); grid on;
                title(['Bootstrapped correlations h=' num2str(hboot(f))],'FontSize',16); hold on
                xlabel('boot correlations','FontSize',14);ylabel('frequency','FontSize',14)
                plot(repmat(CI(1,f),max(hist(rsb(:,f),k)),1),[1:max(hist(rsb(:,f),k))],'r','LineWidth',4);
                plot(repmat(CI(2,f),max(hist(rsb(:,f),k)),1),[1:max(hist(rsb(:,f),k))],'r','LineWidth',4);
                axis tight; colormap([.4 .4 1])
                box on;set(gca,'Fontsize',14)
            end
        end
    end
end
    


end


%% ploting with an ellipse around the good data points
function [XEmin, YEmin] = ellipse(X, Y)

% Ellipse function - 15th September 2008
% Returns X and Y values for an ellipse tightly surrounding all the data points
% Designed by Julien Rouger, Voice Neurocognition Laboratory
% Department of Psychology, University of Glasgow 

% Check data format
if size(X, 1) > size(X, 2), X = X'; end
if size(Y, 1) > size(Y, 2), Y = Y'; end

% If the ellipse contains the convex hull, it will contain all data points
k = convhull(X, Y); k = k(1:end-1);
 
th = 0:pi/1000:2*pi;
ct = cos(th); st = sin(th);
xo = X(k); yo = Y(k);
n = size(xo, 2);

area = Inf;

% =================================================================================================================================
% Find best matching ellipse for any given four anchors in the convex hull
for t = 0:pi/16:2*pi
    ct0 = cos(t); st0 = sin(t);
    x = xo * ct0 + yo * st0;
    y = -xo * st0 + yo * ct0;

    % Four nested loops to get only once all ordered groups of 4 points
    for f = 1:n - 3
        for g = f + 1:n - 2
            for h = g + 1:n - 1
                for i = h + 1:n
                    coef1 = [x(f)^2 - x(g)^2; -2*(x(f) - x(g)); y(f)^2 - y(g)^2; -2*(y(f) - y(g))];
                    coef2 = [x(f)^2 - x(h)^2; -2*(x(f) - x(h)); y(f)^2 - y(h)^2; -2*(y(f) - y(h))];
                    coef3 = [x(f)^2 - x(i)^2; -2*(x(f) - x(i)); y(f)^2 - y(i)^2; -2*(y(f) - y(i))];

                    % Gaussian elimination
                    coef1 = coef1 * coef3(4) - coef3 * coef1(4);
                    coef2 = coef2 * coef3(4) - coef3 * coef2(4);
                    coef1 = coef1 * coef2(2) - coef2 * coef1(2);

                    % k = b^2/a^2
                    k = -coef1(3) / coef1(1);

                    % k negative -> no solution for these 4 points
                    if k > 0
                        coef2(3) = coef2(3) + coef2(1) * k; coef2(1) = 0;
                        coef3(3) = coef3(3) + coef3(1) * k; coef3(1) = 0;

                        % Gaussian elimination
                        coef2(2) = coef2(2) * k; coef3(2) = coef3(2) * k;
                        xc = -coef2(3) / coef2(2);
                        yc = -(coef3(2) * xc + coef3(3)) / coef3(4);
                        a = sqrt((x(f) - xc)^2 + (y(f) - yc)^2 / k);
                        b = sqrt(k * a^2);
                        XE = xc + a * ct;
                        YE = yc + b * st;

                        % Check if ellipse contains all points from the convex hull
                        ok = 1;
                        for j = 1:n
                            dx = x(j) - xc; dy = y(j) - yc;
                            rx = dx / a;
                            ry = dy / b;
                            if rx * rx + ry * ry > 1.0001
                                ok = 0;
                            end
                        end

                        % Update best fitting ellipse
                        if ok == 1 && a * b < area
                            area = a * b;
                            amin = a;
                            bmin = b;
                            xcmin = xc;
                            ycmin = yc;
                            tmin = t;
                        end
                    end
                end
            end
        end
    end
end

if area < Inf
    ct0 = cos(tmin); st0 = sin(tmin);
    XE = xcmin + amin * ct;
    YE = ycmin + bmin * st;
    XEmin = XE * ct0 - YE * st0;
    YEmin = XE * st0 + YE * ct0;
end;


% Previous part found the best matching ellipse for any group of 4 points
% That's fine, but may be there exist better matches using groups of 3 points

% =================================================================================================================================
% Find best matching ellipse for any given three anchors in the convex hull
x = xo; y = yo;

% Three nested loops to get only once all ordered groups of 3 points
for f = 1:n - 2
    for g = f + 1:n - 1
        for h = g + 1:n
            xc = (x(f) + x(g) + x(h)) / 3;
            yc = (y(f) + y(g) + y(h)) / 3;

            % Centre of gravity of this triangle
            a(1) = x(f) - xc; b(1) = y(f) - yc;
            a(2) = x(g) - xc; b(2) = y(g) - yc;
            a(3) = x(h) - xc; b(3) = y(h) - yc;

            % Newton iterative method
            theta = pi; error = 1;
            while abs(error) > 1e-6
                cth = cos(theta); sth = sin(theta);
                a1 = a(1) * cth + b(1) * sth; b1 = -a(1) * sth + b(1) * cth;
                a2 = a(2) * cth + b(2) * sth; b2 = -a(2) * sth + b(2) * cth;
                a3 = a(3) * cth + b(3) * sth; b3 = -a(3) * sth + b(3) * cth;
                da1 = a1 - a2; da2 = a2 - a3; da3 = a3 - a1;
                db1 = b1 - b2; db2 = b2 - b3; db3 = b3 - b1;
                fth = (da1.^2 - da2.^2).*(db1.^2 - db3.^2)-(da1.^2 - da3.^2).*(db1.^2 - db2.^2);
                dfth = 2*(da1.*db1 - da2.*db2).*(db1.^2 - db3.^2 + da1.^2 - da3.^2)- 2*(db1.*da1 - db3.*da3).*(da1.^2 - da2.^2 + db1.^2 - db2.^2);
                error = - fth / dfth;
                theta = theta + error;
            end
            cth = cos(theta); sth = sin(theta);
            a1 = a(1) * cth + b(1) * sth; b1 = -a(1) * sth + b(1) * cth;
            a2 = a(2) * cth + b(2) * sth; b2 = -a(2) * sth + b(2) * cth;
            a3 = a(3) * cth + b(3) * sth; b3 = -a(3) * sth + b(3) * cth;
            da1 = a1 - a2; da2 = a2 - a3;
            db1 = b1 - b2; db2 = b2 - b3;
            k = sqrt(-(da1.^2 - da2.^2) / (db1.^2 - db2.^2));

            R = sqrt(((a1 - a2)^2 + k^2 * (b1 - b2)^2) / 3);

            XE = xc + R * (ct * cth - st / k * sth);
            YE = yc + R * (ct * sth + st / k * cth);

            % Check if ellipse contains all points from the convex hull
            ok = 1;
            for i = 1:n
                dx = x(i) - xc; dy = y(i) - yc;
                rx = dx * cth + dy * sth;
                ry = k * (-dx * sth + dy * cth);
                if rx * rx + ry * ry > 1.0001 * R^2
                    ok = 0;
                end
            end

            % Update best fitting ellipse
            if ok == 1 && R * R / k < area
                area = R * R / k;
                XEmin = XE;
                YEmin = YE;
            end
        end
    end
end
end
