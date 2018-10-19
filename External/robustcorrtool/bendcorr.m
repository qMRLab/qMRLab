function [r,t,p,hboot,CI,H,pH] = bendcorr(X,Y,fig_flag,beta)

% Computes the percentage bend correlation along with the bootstrap CI
%
% FORMAT:  [r,t,p] = bendcorr(X,Y)
%          [r,t,p,hboot,CI,H,pH] = bendcorr(X,Y,fig_flag,beta)
%
% INPUTS:  X and Y are 2 vectors or matrices. In the latter case,
%          correlations are computed column-wise. 
%          fig_flag indicates to plot (1 - default) the data or not (0)
%          beta represents the amount of trimming: 0 <= beta <= 0.5
%          (beta is also called the bending constant for omega - default = 0.2)
%
% OUTPUTS: r is the percentage bend correlation
%          t is the associated t value
%          pval is the corresponding p value
%          hboot 1/0 declares the test significant based on CI
%          CI is the percentile bootstrap confidence interval
%          H is the measure of association between all pairs
%          pH is the p value for an omnibus test of independence between all pairs 
%
% The percentage bend correlation is a robust method that protects against
% outliers among the marginal distributions.

% Cyril Pernet and Guillaume Rousselet 26-01-2011
% Reformatted for Corr_toolbox 02--7-2012 
% ----------------------------------------------
%  Copyright (C) Corr_toolbox 2012

%% data check

if nargin<2
    error('two input vectors requested')
elseif nargin>4
    eror('too many inputs')
end

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
level = 5/100;
if nargin < 2
    error('two inputs requested');
elseif nargin == 2
    fig_flag = 1;
    beta = 0.2;
elseif nargin == 3
    beta = 0.2;
end

if beta>1
    beta = beta/100;
end

if beta<0 || beta>.5
    error('beta must be between 0 and 50%')
end

% remove NaNs
% -----------
X = [X Y];
X(find(sum(isnan(X),2)),:) = [];
n = length(X);

%% compute
% --------
if nargout > 5
    [r,t,p,XX,YY,H,pH] = bend_compute(X,beta);
else
    [r,t,p,XX,YY] = bend_compute(X,beta);
end

if nargout > 3 
    % bootstrap
    % -----------
    nboot = 1000;
    level = level / (size(X,2)/2);
     
    low = round((level*nboot)/2);
    if low == 0
        error('adjusted CI cannot be computed, too many tests for the number of observations')
    else
        high = nboot - low;
    end
     
    table = randi(n,n,nboot);
    for B=1:nboot
        tmp = X(table(:,B),:);
        rb(B,:) = bend_compute(tmp,beta);
        for c=1:size(X,2)/2
            coef = pinv([tmp(:,c) ones(n,1)])*tmp(:,c+size(X,2)/2); 
            intercept(B,c) = coef(2);
            slope(B,c) = rb(B,c) / (std(tmp(:,c))/std(tmp(:,c+size(X,2)/2)));
        end
    end
    
    rb = sort(rb);
    slope = sort(slope,1);
    intercept = sort(intercept,1);

    % CI and h
    adj_nboot = nboot - sum(isnan(rb));
    adj_low = round((level*adj_nboot)/2);
    adj_high = adj_nboot - adj_low;
    
    for c=1:size(X,2)/2
        CI(:,c) = [rb(adj_low(c),c) ; rb(adj_high(c),c)];
        hboot(c) = (rb(adj_low(c),c) > 0) + (rb(adj_high(c),c) < 0);
        CIslope(:,c) = [slope(adj_low(c),c) ; slope(adj_high(c),c)];
        CIintercept(:,c) = [intercept(adj_low(c),c) ; intercept(adj_high(c),c)];
    end
end
 
%% plot
% -----
if fig_flag ~= 0
    answer = [];
    if size(r,1) > 1
        answer = questdlg('plots all correlations','Plotting option','yes','no','yes');
    else
        if fig_flag == 1
            figure('Name','Bend correlation');
            set(gcf,'Color','w');
        end
        
        if nargout >3
            subplot(1,2,1);
            M = sprintf('Bend corr r=%g \n %g%%CI [%g %g]',r,(1-level)*100,rb(low),rb(high));
        else
            M = sprintf('Bend corr r=%g \n p=%g',r,p);
        end
        
        scatter(X(:,1),X(:,2),100,'filled');
        hold on; grid on;
        % plot 'outliers'
        scatter(X(XX{1},1),X(XX{1},2),110,'r','LineWidth',3);
        scatter(X(YY{1},1),X(YY{1},2),110,'g','LineWidth',3);
        scatter(X(intersect(XX{1},YY{1}),1),X(intersect(XX{1},YY{1}),2),110,'k','LineWidth',3);
        xlabel('X bend','FontSize',12); ylabel('Y bend','FontSize',12);
        title(M,'FontSize',16); 
        coef = pinv([X(:,1) ones(n,1)])*X(:,2);
        s = r / (std(X(:,1))/std(X(:,2)));
        h = refline(s,coef(2)); set(h,'Color','r','LineWidth',4);
        box on;set(gca,'FontSize',14)
        
        if  nargout>3
            if sum(slope == 0) == 0
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
            end
            
            subplot(1,2,2); k = round(1 + log2(length(rb))); hist(rb,k); grid on;
            title({'Bootstrapped correlations';['h=' num2str(hboot)]},'FontSize',16); hold on
            xlabel('boot correlations','FontSize',14);ylabel('frequency','FontSize',14)
            plot(repmat(CI(1),max(hist(rb,k)),1),[1:max(hist(rb,k))],'r','LineWidth',4);
            plot(repmat(CI(2),max(hist(rb,k)),1),[1:max(hist(rb,k))],'r','LineWidth',4);
            axis tight; colormap([.4 .4 1])
            box on;set(gca,'FontSize',14,'Layer','Top')
        end
    end
    
    if strcmp(answer,'yes')
        for f = 1:length(r)
            if fig_flag == 1
                figure('Name',[num2str(f) ' boostrapped Bend correlation']);
                set(gcf,'Color','w');
            end
            
            if nargout > 3
                subplot(1,2,1);
                M = sprintf('Bend corr r=%g \n %g%%CI [%g %g]',r(f),(1-level)*100,CI(1,f),CI(2,f));
            else
                M = sprintf('Bend corr r=%g p=%g',r(f),p(f));
            end
            
            scatter(X(:,f),X(:,f+size(X,2)/2),100,'b','filled'); 
            hold on; grid on; 
            % plot 'outliers'
            scatter(X(XX{f},f),X(XX{f},f+size(X,2)/2),110,'r','LineWidth',3); 
            scatter(X(YY{f},f),X(YY{f},f+size(X,2)/2),110,'g','LineWidth',3);
            scatter(X(intersect(XX{f},YY{f}),f),X(intersect(XX{f},YY{f}),f+size(X,2)/2),110,'k','LineWidth',3);
            xlabel('X bend','FontSize',12); ylabel('Y bend','FontSize',12);
            title(M,'FontSize',16);
            coef = pinv([X(:,f) ones(n,1)])*X(:,f+size(X,2)/2);
            s = r(f) / (std(X(:,f))/std(X(:,f+size(X,2)/2)));
            h = refline(s,coef(2)); set(h,'Color','r','LineWidth',4);
            box on;set(gca,'FontSize',14,'Layer','Top')
            
            if nargout >3
                if sum(slope(:,f) == 0) == 0
                    y1 = refline(CIslope(1,f),CIintercept(1,f)); set(y1,'Color','r');
                    y2 = refline(CIslope(2,f),CIintercept(2,f)); set(y2,'Color','r');
                    y1 = get(y1); y2 = get(y2);
                    xpoints=[[y1.XData(1):y1.XData(2)],[y2.XData(2):-1:y2.XData(1)]];
                    step1 = y1.YData(2)-y1.YData(1); step1 = step1 / (y1.XData(2)-y1.XData(1));
                    step2 = y2.YData(2)-y2.YData(1); step2 = step2 / (y2.XData(2)-y2.XData(1));
                    filled=[[y1.YData(1):step1:y1.YData(2)],[y2.YData(2):-step2:y2.YData(1)]];
                    hold on; fillhandle=fill(xpoints,filled,[1 0 0]);
                    set(fillhandle,'EdgeColor',[1 0 0],'FaceAlpha',0.2,'EdgeAlpha',0.8);%set edge color
                    box on;set(gca,'FontSize',14,'Layer','Top')
                end
                
                subplot(1,2,2); k = round(1 + log2(size(rb,1))); hist(rb(:,f),k); grid on;
                title({'Bootstrapped correlations';['h=',num2str(hboot(f))]},'FontSize',16); hold on
                xlabel('boot correlations','FontSize',14);ylabel('frequency','FontSize',14)
                plot(repmat(CI(1,f),max(hist(rb(:,f),k)),1),[1:max(hist(rb(:,f),k))],'r','LineWidth',4);
                plot(repmat(CI(2,f),max(hist(rb(:,f),k)),1),[1:max(hist(rb(:,f),k))],'r','LineWidth',4);
                axis tight; colormap([.4 .4 1])
                box on;set(gca,'FontSize',14,'Layer','Top')
            end
        end
    end
end

end

function [r,t,p,XX,YY,H,pH] = bend_compute(X,beta)

H= []; pH = [];

%% Medians and absolute deviation from the medians
% ---------------------------------------------
M = repmat(median(X),size(X,1),1);
W = sort(abs(X-M),1); 
 
% limits
% -------
m = floor((1-beta)*size(X,1));
omega = W(m,:); 

%% Compute the correlation
% ------------------------
P = (X-M)./ repmat(omega,size(X,1),1); 
P(isnan(P)) = 0; P(isinf(P)) = 0; % correct if omega = 0
comb = [(1:size(X,2)/2)',((1:size(X,2)/2)+size(X,2)/2)']; % all pairs of columns
r = NaN(size(comb,1),1); 
t = r; p = t;

for j = 1:size(comb,1)
    
    % column 1
    psi = P(:,comb(j,1)); 
    i1 = length(psi(psi<-1)); 
    i2 = length(psi(psi>1)); 
    sx = X(:,comb(j,1)); 
    sx(psi<(-1)) = 0; 
    sx(psi>1) = 0; 
    pbos = (sum(sx)+ omega(comb(j,1))*(i2-i1)) / (size(X,1)-i1-i2); 
    a = (X(:,comb(j,1))-pbos)./repmat(omega(comb(j,1)),size(X,1),1); 
        
    % column 2
    psi = P(:,comb(j,2));
    i1 = length(psi(psi<-1));
    i2 = length(psi(psi>1));
    sx = X(:,comb(j,2));
    sx(psi<(-1)) = 0;
    sx(psi>1) = 0;
    pbos = (sum(sx)+ omega(comb(j,2))*(i2-i1)) / (size(X,1)-i1-i2);
    b = (X(:,comb(j,2))-pbos)./repmat(omega(comb(j,2)),size(X,1),1);
    
     % return values of a,b to plot 
     XX{j} = union(find(a <= -1),find(a >= 1)); 
     YY{j} = union(find(b <= -1),find(b >= 1));
     
     % bend
     a(a<=-1) = -1; a(a>=1) = 1; 
     b(b<=-1) = -1; b(b>=1) = 1; 
     
     % get r, t and p
     r(j) = sum(a.*b)/sqrt(sum(a.^2)*sum(b.^2));
     t(j) = r(j)*sqrt((size(X,1) - 2)/(1 - r(j).^2));
     p(j) = 2*(1 - tcdf(abs(t(j)),size(X,1)-2));

end

if size(X,2) > 2 && nargout > 5
    bv = 48*(size(X,1)-2.5).^2;
    for j=1:length(comb)
        c(j) = sqrt((size(X,1)-2.5)*log(1+t(j)^2/(size(X,1)-2))); % S plus: cmat<-sqrt((nrow(m)-2.5)*log(1+tstat^2/(nrow(m)-2)))\
        z(j) = c(j) + (c(j)^3+3*c(j))/bv - ( (4*c(j).^7+33*c(j).^5+240*c(j)^3+855*c(j)) / (10*bv.^2+8*bv*c(j).^4+1000*bv) ); % S plus: cmat<-cmat+(cmat^3+3*cmat)/bv-(4*cmat^7+33*cmat^5+240^cmat^3+855*cmat)/(10*bv^2+8*bv*cmat^4+1000*bv)\
    end
    H =  sum(z.^2);
    pH= 1- cdf('chi2',H,(size(X,2)*(size(X,2)-1))/2);
end

end