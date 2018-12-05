function [r,t,pval,hboot,CI,hout] = Pearson(X,Y,XLabel,YLabel,fig_flag,level)

% compute the Pearson correlation along with the bootstrap CI
%
% FORMAT:  [r,t,p] = Pearson(X,Y)
%          [r,t,p] = Pearson(X,Y,fig_flag,level)
%          [r,t,p,hboot,CI] = Pearson(X,Y,fig_flag,level)
%
% INPUTS:  X and Y are 2 vectors or matrices, in the latter case,
%          correlations are computed column-wise
%          fig_flag indicates to plot (default = 1) the data or not (0)
%          level is the desired alpha level (default = 5%)
%
% OUTPUTS: r is the Pearson correlation
%          t is the associated t value
%          pval is the corresponding p value
%
%          optional:
%
%          hboot 1/0 declares the test significant based on CI
%          CI is the percentile bootstrap confidence interval
%
% If X and Y are matrices of size [n p], p correlations are computed
% consequently, the CI are adjusted at a level alpha/p (Bonferonni
% correction) and hboot is based on these adjusted CI (pval remain
% uncorrected)

% Cyril Pernet v1
% ---------------------------------
%  Copyright (C) Corr_toolbox 2012

%% data check
% #qmrstat
PyVis = struct();


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
    % #qmrstat
    level = 5/100;
elseif nargin == 5
    % #qmrstat
    level = 5/100;
end

[n p] = size(X);

%% basic Pearson

% compute r
r = sum(detrend(X,'constant').*detrend(Y,'constant')) ./ ...
    (sum(detrend(X,'constant').^2).*sum(detrend(Y,'constant').^2)).^(1/2);
t = r.*sqrt((n-2)./(1-r.^2));
pval = 2*tcdf(-abs(t),n-2);

if nargout > 3
    % adjust boot parameters
    if p == 1
        nboot = 599;
        % adjust percentiles following Wilcox
        if n < 40
            low = 7 ; high = 593;
        elseif n >= 40 && n < 80
            low = 8 ; high = 592;
        elseif n >= 80 && n < 180
            low = 11 ; high = 588;
        elseif n >= 180 && n < 250
            low = 14 ; high = 585;
        elseif n >= 250
            low = 15 ; high = 584;
        end

    else
        nboot = 1000;
        level = level / p;
        % Bonferonni correction
        low = round((level*nboot)/2);
        if low == 0
            error('adjusted CI cannot be computed, too many tests for the number of observations')
        else
            high = nboot - low;
        end
    end
    % compute hboot and CI
    table = randi(n,n,nboot);
    for B=1:nboot
        rb(B,:) = sum(detrend(X(table(:,B),:),'constant').*detrend(Y(table(:,B),:),'constant')) ./ ...
            (sum(detrend(X(table(:,B),:),'constant').^2).*sum(detrend(Y(table(:,B),:),'constant').^2)).^(1/2);
        for c=1:size(X,2)
            b = pinv([X(table(:,B),c) ones(n,1)])*Y(table(:,B),c);
            slope(B,c) = b(1);
            intercept(B,c) = b(2,:);
        end
    end

    rb = sort(rb,1);
    [slope,index] = sort(slope,1);
    % in theory we keep the slope/intercept pair, thus:
    % intercept = intercept(index); % but doesn't work?
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

            % #qmrstat
            if nargout == 6
                hout = figure('Name','Pearson correlation');
                set(gcf,'Color','w');
                set(hout,'Visible','off');

            else % When hout is not a nargout

                figure('Name','Pearson correlation');
                set(gcf,'Color','w');

            end



        if nargout>3
            % #qmrstat
            % This is always the case with calls from qmrstat
            M = sprintf('Pearson corr r=%g \n %g%%CI [%g %g]',r,(1-level)*100,CI(1),CI(2));
        else
            M = sprintf('Pearson corr r=%g \n p=%g',r,pval);
        end

        scatter(X,Y,100,'filled'); grid on
        xlabel(XLabel,'FontSize',14); ylabel(YLabel,'FontSize',14);
        title(M,'FontSize',16);
        % #octaveIssue
        h=lsline; set(h,'Color','r','LineWidth',4);
        % #qmrstat
        PyVis.FitLine.X = get(h,'XData');
        PyVis.FitLine.Y = get(h,'YData');

        box on;set(gca,'Fontsize',14)

        % REFLINE AND LSLINE ARE NOT AVAILABLE FOR OCTAVE.

        if nargout>3 % if bootstrap done plot CI
            y1 = refline(CIslope(1),CIintercept(1)); set(y1,'Color','r');
            y2 = refline(CIslope(2),CIintercept(2)); set(y2,'Color','r');
            y1 = get(y1); y2 = get(y2);
            xpoints=[y1.XData(1):y1.XData(2),y2.XData(2):-1:y2.XData(1)];
            step1 = y1.YData(2)-y1.YData(1); step1 = step1 / (y1.XData(2)-y1.XData(1));
            step2 = y2.YData(2)-y2.YData(1); step2 = step2 / (y2.XData(2)-y2.XData(1));
            filled=[y1.YData(1):step1:y1.YData(2),y2.YData(2):-step2:y2.YData(1)];


            PyVis.CILine1.X = [y1.XData(1),y1.XData(2)];
            PyVis.CILine1.Y = [y1.YData(1),y1.YData(2)];

            PyVis.CILine2.X = [y2.XData(1),y2.XData(2)];
            PyVis.CILine2.Y = [y2.YData(1),y2.YData(2)];


            if min(CI)<0 && max(CI)>0
                fillColor = [1,0,0];
            else
                fillColor = [0,1,0];
            end
            PyVis.fillColor = sprintf('rgb(%d,%d,%d)',255*fillColor(1),255*fillColor(2),255*fillColor(3));

            assignin('caller','PyVis',PyVis);

            hold on; fillhandle=fill(xpoints,filled,fillColor);
            set(fillhandle,'EdgeColor',[0 0 0],'FaceAlpha',0.2,'EdgeAlpha',0.8);%set edge color

        end
    end

end
