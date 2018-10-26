function [CIP,pP,CIC,pC]=spmrt_compcorr(X,Y,metric,figout,threshold,alpha_level)

% Implementation of a percentile bootstrap of the difference of correlation
% for dependent measures - think of comparing the reliability (corr) of two MRI
% sequences or two paradigms.
%
% X[N,2]
% Y[N,2]
% 
% FORMAT [diffP,CIP,diffC,CIC]=spmrt_compcorr
%        [diffP,CIP]=spmrt_compcorr(pair1,pair2,mask,'Pearson',figout,threshold,alpha_level)
%        [diffC,CIC]=spmrt_compcorr(pair1,pair2,mask,'Concordance',figout,threshold,alpha_level)
%
% INPUT if no input the user is prompted
%       pair1 is a char array with the filenames of 2 images to correlate (see spm_select)
%       pair2 is a char array with the filenames of 2 images to correlate (see spm_select)
%       mask   is the filename of a mask in same space as image1 and image2
%       metric is 'Pearson', 'Concordance', or 'both'
%       figout 1/0 (default) to get correlation figure out
%       threshold (optional) if mask is not binary, threshold to apply
%       alpha_level is the level used to compute the confidence interval (default is 5%)
%
% OUTPUT CIP is the 95% confidence interval of the difference in Pearson correlation coefficient (if 0 not included then significant)
%        pP is the p value associated with CIP
%        CIC is the 95% confidence interval of the difference in concordance correlation coefficient (if 0 not included then significant)
%        pC is the p value associated with CIC
%
% Reference: Wilcox, R.R. (2016) Comparing dependent robust correlations.
% Brit J Math Stat Psy, 69, 215-224. http://onlinelibrary.wiley.com/doi/10.1111/bmsp.12069/full
%
% Cyril Pernet
% Modified by Agah Karakuzu for qMRLab (2018)
% --------------------------------------------------------------------------
% Copyright (C) spmrt

CIP = [];
CIC = [];
nboot = 1000; % a thousand bootstraps



%% Pearson correlation
if strcmpi(metric,'Pearson') || strcmpi(metric,'Both')
    
    disp('computing Pearson correlation differences');
    table = randi(nx,nx,nboot);
    rP1 = sum(detrend(reshape(X(table,1),[nx nboot]),'constant').*detrend(reshape(X(table,2),[nx nboot]),'constant')) ./ ...
        (sum(detrend(reshape(X(table,1),[nx nboot]),'constant').^2).*sum(detrend(reshape(X(table,2),[nx nboot]),'constant').^2)).^(1/2);
    
    rP2 = sum(detrend(reshape(Y(table,1),[nx nboot]),'constant').*detrend(reshape(Y(table,2),[nx nboot]),'constant')) ./ ...
        (sum(detrend(reshape(Y(table,1),[nx nboot]),'constant').^2).*sum(detrend(reshape(Y(table,2),[nx nboot]),'constant').^2)).^(1/2);
    
    bootdiffP = sort(rP1 - rP2);
    bootdiffP(isnan(bootdiffP)) = [];
    adj_nboot = length(bootdiffP);
    low = round((alpha_level*adj_nboot)/2); % lower bound
    high = adj_nboot - low; % upper bound
    CIP = [bootdiffP(low) bootdiffP(high)];
    pvalue = mean(bootdiffP < 0);
    pP = 2*min(pvalue,1-pvalue);
    if pP == 0
        pP = 1/nboot;
    end
end


%% Concordance
if strcmpi(metric,'Concordance') || strcmpi(metric,'Both')
    
    if strcmpi(metric,'Concordance')
        table = randi(nx,nx,nboot); % otherwise reuse the one from above = same sampling scheme
    end
    
    bootdiffC = zeros(1,nboot); % Agah 
    for b=1:nboot
        S = cov(X(table(:,b),:),1); Var1 = S(1,1); Var2 = S(2,2); S = S(1,2);
        r1 = (2.*S) ./ (Var1+Var2+((mean(X(table(:,b),1)-mean(X(table(:,b),2)).^2))));
        S = cov(Y(table(:,b),:),1); Var1 = S(1,1); Var2 = S(2,2); S = S(1,2);
        r2 = (2.*S) ./ (Var1+Var2+((mean(Y(table(:,b),1)-mean(Y(table(:,b),2)).^2))));
        bootdiffC(b) = r1-r2;
    end
    
    bootdiffC = sort(bootdiffC,1);
    bootdiffC(isnan(bootdiffC)) = [];
    adj_nboot = length(bootdiffC);
    low = round((alpha_level*adj_nboot)/2); % lower bound
    high = adj_nboot - low; % upper bound
    CIC = [bootdiffC(low) bootdiffC(high)];
    pvalue = mean(bootdiffC < 0);
    pC = 2*min(pvalue,1-pvalue);
    if pC == 0
        pC = 1/nboot;
    end
end

%% figure
if figout == 1
    figure('Name','images correlation')
    set(gcf,'Color','w','InvertHardCopy','off', 'units','normalized','outerposition',[0 0 1 1])
    
    % left plot
    [rP1,CIP1,rC1,CIC1] = spmrt_corr(X,'both',0,alpha_level);
    
    if strcmpi(metric,'Pearson')
        subplot(1,3,1); 
        mytitle = sprintf('Pearson corr =%g \n CI [%g %g]',rP1,CIP1(1),CIP1(2));
    elseif strcmpi(metric,'Concordance')
         subplot(1,3,1); 
        mytitle =  sprintf('Concordance corr =%g \n CI [%g %g]',rC1,CIC1(1),CIC1(2));
    else
        subplot(4,3,[4 7]); 
        mytitle = sprintf('Pearson corr =%g \n CI [%g %g] \n Concordance corr =%g \n CI [%g %g]',rP1,CIP1(1),CIP1(2),rC1,CIC1(1),CIC1(2));
    end
    scatter(X(:,1),X(:,2),50); grid on % plot observations pair 1
    xlabel('img1 pair1','FontSize',14); ylabel('img2 pair1','FontSize',14); % label
    h=lsline; set(h,'Color','r','LineWidth',4); % add the least square line
    box on; set(gca,'Fontsize',12); axis square; hold on
    v = axis; plot([v(1):[(v(2)-v(1))/10]:v(2)],[v(3):[(v(4)-v(3))/10]:v(4)],'r','LineWidth',2);  % add diagonal
    title(mytitle,'Fontsize',12)
        
    % right plot
    [rP2,CIP2,rC2,CIC2] = spmrt_corr(Y,'both',0,alpha_level);
    if strcmpi(metric,'Pearson')
        subplot(1,3,3); 
        mytitle = sprintf('Pearson corr =%g \n CI [%g %g]',rP2,CIP2(1),CIP2(2));
    elseif strcmpi(metric,'Concordance')
         subplot(1,3,3); 
        mytitle =  sprintf('Concordance corr =%g \n CI [%g %g]',rC2,CIC2(1),CIC2(2));
    else
        subplot(4,3,[6 9]); 
        mytitle = sprintf('Pearson corr =%g \n CI [%g %g] \n Concordance corr =%g \n CI [%g %g]',rP2,CIP2(1),CIP2(2),rC2,CIC2(1),CIC2(2));
    end
    
    scatter(Y(:,1),Y(:,2),50); grid on % plot observations pair 1
    xlabel('img1 pair2','FontSize',14); ylabel('img2 pair2','FontSize',14); % label
    h=lsline; set(h,'Color','r','LineWidth',4); % add the least square line
    box on; set(gca,'Fontsize',12); axis square; hold on
    vv = axis; plot([vv(1):[(vv(2)-vv(1))/10]:vv(2)],[vv(3):[(vv(4)-vv(3))/10]:vv(4)],'r','LineWidth',2);  % add diagonal
    title(mytitle,'Fontsize',12)
    
    % middle plot
    if strcmpi(metric,'Pearson')
        subplot(1,3,1);
    elseif strcmpi(metric,'Concordance')
        subplot(1,3,1);
    else
        subplot(4,3,[2 5]);
        k = round(1 + log2(length(bootdiffP)));
        [n,x]=hist(bootdiffP,k); h = x(2) - x(1);
        bar(x,n/(length(bootdiffP)*h),1, ...
            'FaceColor',[0.5 0.5 1],'EdgeColor',[0 0 0], ...
            'FaceAlpha',0.9,'EdgeAlpha',1); grid on; box on
        ylabel('Freq.','FontSize',12)
        title(sprintf('Differences in Pearsons'' corr \n %g CI [%g %g]',rP1-rP2, CIP(1),CIP(2)),'Fontsize',12)
        
        subplot(4,3,[8 11]);
        k = round(1 + log2(length(bootdiffC)));
        [n,x]=hist(bootdiffC,k); h = x(2) - x(1);
        bar(x,n/(length(bootdiffC)*h),1, ...
            'FaceColor',[0.5 0.5 1],'EdgeColor',[0 0 0], ...
            'FaceAlpha',0.9,'EdgeAlpha',1); grid on; box on
        xlabel('differences','FontSize',12); ylabel('Freq.','FontSize',12)
        title(sprintf('Differences in Concordance corr \n %g CI [%g %g]',rC1-rC2, CIC(1),CIC(2)),'Fontsize',12)
    end
end


