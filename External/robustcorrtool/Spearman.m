function [r,t,pval,hboot,CI] = Spearman(X,Y,fig_flag,level)

% Computes the Spearman correlation with its bootstrap CI.
%
% FORMAT:  [r,t,p] = Spearman(X,Y)
%          [r,t,p] = Spearman(X,Y,fig_flag,level)
%          [r,t,p,hboot,CI] = Spearman(X,Y,fig_flag,level)
%
% INPUTS:  X and Y are 2 vectors or matrices, in the latter case,
%          correlations are computed column-wise 
%          fig_flag indicates to plot (1 - default) the data or not (0)
%          level is the desired alpha level (5/100 is the default)
%
% OUTPUTS: r is the Spearman correlation
%          t is the associated t value
%          pval is the corresponding p value
%          hboot 1/0 declares the test significant based on CI
%          CI is the percentile bootstrap confidence interval
%
% If X and Y are matrices of size [n p], p correlations are computed
% and the CIs are adjusted at the alpha/p level (Bonferonni
% correction); hboot is based on these adjusted CIs but pval remains
% uncorrected.
%
% This function requires the tiedrank.m function from the matlab stat toolbox. 
%
% See also TIEDRANK.

% Cyril Pernet v1
% ---------------------------------
%  Copyright (C) Corr_toolbox 2012

%% data check

% if X a vector and Y a matrix, 
% repmat X to perform multiple tests on Y (or the other around)
if size(X,1) == 1 && size(X,2) > 1; X = X'; end
if size(Y,1) == 1 && size(Y,2) > 1; Y = Y'; end

if size(X,2) == 1 && size(Y,2) > 1
    X = repmat(X,1,size(Y,2));
elseif size(Y,2) == 1 && size(X,2) > 1
    Y = repmat(Y,1,size(X,2));
end

if sum(size(X)~=size(Y)) ~= 0
    error('X and Y must have the same size')
end

%% parameters
if nargin < 2
    error('two inputs requested');
elseif nargin == 2
    fig_flag = 1;
    level = 5/100;
elseif nargin == 3
    level = 5/100;
end

[n p] = size(X);

%% basic Spearman

% compute r (default)
xrank = tiedrank(X,0);
yrank = tiedrank(Y,0);
r = sum(detrend(xrank,'constant').*detrend(yrank,'constant')) ./ ...
    (sum(detrend(xrank,'constant').^2).*sum(detrend(yrank,'constant').^2)).^(1/2);
t = r.*(sqrt(n-2)) ./ sqrt((1-r.^2));
pval = 2*tcdf(-abs(t),n-2);
% The corr function in the stat toolbox uses
% permutations for n<10 and some other fancy
% things when n>10 and there are no ties among
% ranks - we just do the standard way.

if nargout > 3
    nboot = 1000;
    if p > 1
        level = level / p;
    end
    low = round((level*nboot)/2);
    if low == 0
        error('adjusted CI cannot be computed, too many tests for the number of observations')
    else
        high = nboot - low;
    end

    % bootstrap
    table = randi(n,n,nboot);
    for B=1:nboot
        xrank = tiedrank(X(table(:,B),:),0);
        yrank = tiedrank(Y(table(:,B),:),0);
        rb(B,:) = sum(detrend(xrank,'constant').*detrend(yrank,'constant')) ./ ...
            (sum(detrend(xrank,'constant').^2).*sum(detrend(yrank,'constant').^2)).^(1/2);
        for c=1:size(X,2)
            b = pinv([xrank(:,c) ones(n,1)])*yrank(:,c);
            slope(B,c) = b(1); intercept(B,c) = b(2,:);
        end
    end
    
    rb = sort(rb,1);
    slope = sort(slope,1);
    intercept = sort(intercept,1);
    
    % CI and h
    adj_nboot = nboot - sum(isnan(rb));
    adj_low = round((level*adj_nboot)/2);
    adj_high = adj_nboot - adj_low;
    
    for c=1:size(X,2)
        CI(:,c) = [rb(adj_low(c),c) ; rb(adj_high(c),c)];
        hboot(c) = (rb(adj_low(c),c) > 0) + (rb(adj_high(c),c) < 0);
        CIslope(:,c) = [slope(adj_low(c),c) ; slope(adj_high(c),c)];
        CIintercept(:,c) = [intercept(adj_low(c),c) ; intercept(adj_high(c),c)];
    end
end

%% plots
if fig_flag ~= 0
    answer = [];
    if p > 1
        answer = questdlg(['plots all ' num2str(p) ' correlations'],'Plotting option','yes','no','yes');
    else
        if fig_flag == 1
            figure('Name','Spearman correlation');
            set(gcf,'Color','w'); 
        end
        
        if nargout>3
            subplot(1,2,1);
            M = sprintf('Spearman corr r=%g \n %g%%CI [%g %g]',r,(1-level)*100,CI(1),CI(2));
        else
            M = sprintf('Spearman corr r=%g p=%g',r,pval);
        end
        
        scatter(xrank,yrank,100,'filled'); grid on
        xlabel('X Rank','FontSize',14); ylabel('Y Rank','FontSize',14);
        title(M,'FontSize',16); 
        h=lsline; set(h,'Color','r','LineWidth',4);
        box on;set(gca,'FontSize',14,'Layer','Top')
        
        if nargout >3
            y1 = refline(CIslope(1),CIintercept(1)); set(y1,'Color','r');
            y2 = refline(CIslope(2),CIintercept(2)); set(y2,'Color','r');
            y1 = get(y1); y2 = get(y2);
            xpoints=[[y1.XData(1):y1.XData(2)],[y2.XData(2):-1:y2.XData(1)]];
            step1 = y1.YData(2)-y1.YData(1); step1 = step1 / (y1.XData(2)-y1.XData(1));
            step2 = y2.YData(2)-y2.YData(1); step2 = step2 / (y2.XData(2)-y2.XData(1));
            filled=[[y1.YData(1):step1:y1.YData(2)],[y2.YData(2):-step2:y2.YData(1)]];
            hold on; fillhandle=fill(xpoints,filled,[1 0 0]);
            set(fillhandle,'EdgeColor',[1 0 0],'FaceAlpha',0.2,'EdgeAlpha',0.8);%set edge color
            box on;set(gca,'FontSize',14)
            
            subplot(1,2,2); hold on
            k = round(1 + log2(length(rb))); hist(rb,k); grid on;
            title({'Bootstrapped correlations';['h=',num2str(hboot)]},'FontSize',16)
            xlabel('boot correlations','FontSize',14);ylabel('frequency','FontSize',14)
            plot(repmat(CI(1),max(hist(rb,k)),1),[1:max(hist(rb,k))],'r','LineWidth',4);
            plot(repmat(CI(2),max(hist(rb,k)),1),[1:max(hist(rb,k))],'r','LineWidth',4);
            axis tight; colormap([.4 .4 1])
            box on;set(gca,'FontSize',14,'Layer','Top')
        end
    end
    
    if strcmp(answer,'yes')
        for f = 1:p
            figure('Color','w','Name',[num2str(f) ' Spearman correlation'])
            
            if nargout >3
                subplot(1,2,1);
                M = sprintf('Spearman corr r=%g \n %g%%CI [%g %g]',r(f),(1-level)*100,CI(1,f),CI(2,f));
            else
                M = sprintf('Spearman corr r=%g p=%g',r(f),pval(f));
            end
            
            scatter(xrank(:,f),yrank(:,f),100,'filled'); grid on
            xlabel('X Rank','FontSize',14); ylabel('Y Rank','FontSize',14);
            title(M,'FontSize',16);
            h=lsline; set(h,'Color','r','LineWidth',4);
            
            if nargout >3
                y1 = refline(CIslope(1,f),CIintercept(1,f)); set(y1,'Color','r');
                y2 = refline(CIslope(2,f),CIintercept(2,f)); set(y2,'Color','r');
                y1 = get(y1); y2 = get(y2);
                xpoints=[[y1.XData(1):y1.XData(2)],[y2.XData(2):-1:y2.XData(1)]];
                step1 = y1.YData(2)-y1.YData(1); step1 = step1 / (y1.XData(2)-y1.XData(1));
                step2 = y2.YData(2)-y2.YData(1); step2 = step2 / (y2.XData(2)-y2.XData(1));
                filled=[[y1.YData(1):step1:y1.YData(2)],[y2.YData(2):-step2:y2.YData(1)]];
                hold on; fillhandle=fill(xpoints,filled,[1 0 0]);
                set(fillhandle,'EdgeColor',[1 0 0],'FaceAlpha',0.2,'EdgeAlpha',0.8);%set edge color
                box on;set(gca,'FontSize',14)
                
                subplot(1,2,2); hold on
                k = round(1 + log2(length(rb(:,f)))); hist(rb(:,f),k); grid on;
                plot(repmat(CI(1,f),max(hist(rb(:,f),k)),1),[1:max(hist(rb(:,f),k))],'r','LineWidth',4);
                plot(repmat(CI(2,f),max(hist(rb(:,f),k)),1),[1:max(hist(rb(:,f),k))],'r','LineWidth',4);
                title({'Bootstrapped correlations';['h=',num2str(hboot(f))]},'FontSize',16)
                xlabel('boot correlations','FontSize',14);ylabel('frequency','FontSize',14)
                axis tight; colormap([.4 .4 1])
                box on;set(gca,'FontSize',14,'Layer','Top')
            end
        end
    end
end






