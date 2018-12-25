function [r,t,pval,hboot,CI,hout] = Spearman(X,Y,XLabel,YLabel,fig_flag,level)
% Computes the Spearman correlation with its bootstrapped CI.
%
%
% INPUTS:  X and Y are 2 vectors.
%          XLabel and YLabel are nametags for them.
%          fig_flag indicates to plot (1 - default) the data or not (0)
%          level is the desired alpha level (5/100 is the default)
%
% OUTPUTS: r is the Spearman correlation
%          t is the associated t value
%          pval is the corresponding p value
%          hboot 1/0 declares the test significant based on CI
%          CI is the percentile bootstrap confidence interval
%
%          optional: hout (outputs figure handle)
%
%
% This function requires the tiedrank.m function from the matlab stat toolbox.
%
% See also TIEDRANK.
% Cyril Pernet v1
% Modified by Agah Karakuzu for qmrstat (2018).
% ---------------------------------
%  Copyright (C) Corr_toolbox 2012

% #qmrstat
svds = struct();

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

[n ~] = size(X);

%% basic Spearman

% Rank
xrank = tiedrank(X,0);
yrank = tiedrank(Y,0);
% Compute r (Spearman correlation coefficient)
r = sum(detrend(xrank,'constant').*detrend(yrank,'constant')) ./ ...
    (sum(detrend(xrank,'constant').^2).*sum(detrend(yrank,'constant').^2)).^(1/2);
% Compute t
t = r.*(sqrt(n-2)) ./ sqrt((1-r.^2));
% Compute p-val
pval = 2*tcdf(-abs(t),n-2);


% The corr function in the stat toolbox uses
% permutations for n<10 and some other fancy
% things when n>10 and there are no ties among
% ranks - we just do the standard way.

    nboot = 1000;

    low = round((level*nboot)/2);

    if low == 0
        warning('adjusted CI cannot be computed, too many tests for the number of observations');
        CI = [];

    else
        high = nboot - low;
        CI = zeros(2,1);
    end

  if not(isempty(CI))
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

  else

    if pval < level
    hboot = 1;
    else
    hboot = 0;
    end

  end

%% plots
if fig_flag ~= 0

        if fig_flag == 1
            % #qmrstat ---- start
            if nargout == 6
                hout = figure('Name','Spearman correlation');
                set(gcf,'Color','w');
                set(hout,'Visible','off');

            else % When hout is not a nargout

                figure('Name','Spearman correlation');
                set(gcf,'Color','w');

            end
            % #qmrstat ---- start
        end

        if not(isempty(CI))
            M = sprintf('Spearman corr r=%g \n %g%%CI [%g %g]',r,(1-level)*100,CI(1),CI(2));
        else
            M = sprintf('Spearman corr r=%g p=%g',r,pval);
        end

        scatter(xrank,yrank,100,'filled'); grid on
        xlabel(XLabel,'FontSize',14); ylabel(YLabel,'FontSize',14);
        title(M,'FontSize',16);

        % #octaveIssue
        h=lsline; set(h,'Color','r','LineWidth',4);
        svds.Optional.fitLine = [get(h,'XData'),get(h,'YData')];

        box on;set(gca,'FontSize',14,'Layer','Top')

        % #qmrstat -- start
        svds.Required.xData = xrank';
        svds.Required.yData = yrank';
        % #qmrstat -- start

        if not(isempty(CI))
            % #octaveIssue
            y1 = refline(CIslope(1),CIintercept(1)); set(y1,'Color','r');
            y2 = refline(CIslope(2),CIintercept(2)); set(y2,'Color','r');
            y1 = get(y1); y2 = get(y2);

            xpoints=[[y1.XData(1):y1.XData(2)],[y2.XData(2):-1:y2.XData(1)]];
            step1 = y1.YData(2)-y1.YData(1); step1 = step1 / (y1.XData(2)-y1.XData(1));
            step2 = y2.YData(2)-y2.YData(1); step2 = step2 / (y2.XData(2)-y2.XData(1));
            filled=[[y1.YData(1):step1:y1.YData(2)],[y2.YData(2):-step2:y2.YData(1)]];

            % #qmrstat ---- start
            svds.Optional.CILine1 = [y1.XData(1),y1.XData(2),y1.YData(1),y1.YData(2)];
            svds.Optional.CILine2 = [y2.XData(1),y2.XData(2),y2.YData(1),y2.YData(2)];

            if min(CI)<0 && max(CI)>0
                fillColor = [1,0,0];
            else
                fillColor = [0,1,0];
            end


            % #qmrstat ---- end

            hold on; fillhandle=fill(xpoints,filled,fillColor);
            set(fillhandle,'EdgeColor',[1 0 0],'FaceAlpha',0.2,'EdgeAlpha',0.8);%set edge color
            box on;set(gca,'FontSize',14)


        end

end
          assignin('caller','svds',svds);
end
