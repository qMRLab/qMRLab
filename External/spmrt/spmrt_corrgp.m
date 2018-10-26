function [W,B,Maps,Stats] = spmrt_corrgp(series1,series2,masks,threshold,covariate,figout)

% Routine that allows to test for image reliability based on correlations. 
% The function calls iteratively spmrt_corr to compute the Pearson and
% concordance correlations between images from series1 and series2
% All pairs are computed to produce within vs. between pairs estimates
% For instance for series1 = [A1 A2 A3] and series2 = [B1 B2 B3],
% Pearson and concordance correlations are computed for [A1B1] [A2B2] and
% [A3B3] giving the within pairs correlations, and mean([A1B2 A1B3]),
% mean([A2B1 A2B3]) and mean([A3B1] [A3B2]) giving the between pairs
% correlations. A bootstrap is then computed to test if the diff = 0.
%
% FORMAT = [W,B,Stats] = spmup_corrgp(series1,series2,masks,figout,threshold)
%
% INPUT series1 series of image filename (see spm_select - e.g. A1 A2 A3)
%       series2 series of image filename (see spm_select  - e.g. B1 B2 B3)
%       --> series are for different subjects, for time series see
%           spmrt_timeseries_corrgp
%       masks series of image filename (see spm_select - e.g. M1 M2 M3)
%           note it is expected that A1 B1 and M1 are from the same subject
%       figout 1/0 (default) to get all correlation figures out
%       threshold (optional) if masks are not binary, threshold to apply
%
% output W are the within pairs correlations (Pearson and Concordance)
%        B are the between pairs correlations (Pearson and Concordance)
%        Maps filenames of the within and between subject maps
%        Stats is structure with mean and medians (with percentille
%        bootstrap 95% CI - to read column-wise) of within, and between 
%        Pearson and Concordance correlation ; as well as the difference 
%        in means and medians. P-values 
%
% Cyril Pernet
% --------------------------------------------------------------------------
% Copyright (C) spmrt

if nargin == 3
    threshold = 0;
    covariate = [];
    figout = 0;    
end

if size(series1,1) ~= size(series2,1)
    error('series 1 and 2 are of different size')
end

if size(masks,1) == 1
    disp('only one mask used for all images')
    masks = repmat(masks,size(series1,1),1);
end

%% do the within loop
N = size(series1,1); 
W = nan(N,2); % <--  within pairs correlations
for n=1:N
    fprintf('Computing within pairs correlations: pair %g/%g \n',n,N)
    [W(n,1),~,W(n,2),~]=spmrt_corr(series1(n,:),series2(n,:),masks(n,:),'both',figout,threshold);
end

%% make map
if nargout == 3
    img1 = spm_read_vols(spm_vol(series1(1,:)));
    img2 = spm_read_vols(spm_vol(series2(1,:)));
    for n=2:N
        img1 = img1+spm_read_vols(spm_vol(series1(n,:)));
        img2 = img2+spm_read_vols(spm_vol(series2(n,:)));
    end
    img1 = img1./N; img2 = img2./N; Wimg = img1-img2;
    WW = spm_vol(series1(1,:)); WW.fname = [pwd filesep 'within_pairs_difference.nii'];
    Maps{1} = spm_write_vol(WW,Wimg); clear WW Wimg img1 img2
end

%% do the between loop
combinations = nchoosek([1:size(series1,1)],2);
B = nan(N,2); % <-- between pairs correlations
MP = NaN(N,N); MC = NaN(N,N); % <-- corr matrices (Pearson / Concordance) for all pairs
for n=1:length(combinations)
    fprintf('Computing between pairs correlations: pair %g/%g \n',n,length(combinations))    
    [MP(combinations(n,1),combinations(n,2)),~,MC(combinations(n,1),combinations(n,2)),~] = spmrt_corr(...
        series1(combinations(n,1),:),series2(combinations(n,2),:),masks(combinations(n,1),:),'both',figout,threshold);
    MP(combinations(n,2),combinations(n,1)) = MP(combinations(n,1),combinations(n,2));
    MC(combinations(n,2),combinations(n,1)) = MC(combinations(n,1),combinations(n,2));
end
B = [nanmean(MP,2) nanmean(MC,2)]; % <-- for a given image, average corr to all others


%% make map
if nargout == 3
    for n=1:N
        img = spm_read_vols(spm_vol(series1(n,:)));
        if n == 1
            Bimg = zeros(size(img));
        end
        
        m = 1:N; m(m==n) = [];
        for d=1:length(m)
            img = img + spm_read_vols(spm_vol(series1(m(d),:)));
        end
        Bimg = Bimg + img./n;
    end
    BB = spm_vol(series1(1,:)); BB.fname = [pwd filesep 'between_pairs_difference.nii'];
    Maps{2} = spm_write_vol(BB,Bimg); clear BB Bimg img
end
    

%% do the stats
if nargout == 4
   disp('Computing the stats')
   if ~isempty(covariate)
       disp('adjusting data for the covariate')
       b = pinv(covariate)*(W-mean(W));
       W = W-(covariate*b);
       b = pinv(covariate)*(B-mean(B));
       B = B-(covariate*b);
   end
   
   Stats.means_within    = mean(W);
   Stats.means_between   = mean(B);
   Stats.medians_within  = median(W);
   Stats.medians_between = median(B);

   % percentile bootstrap on the difference
   nboot = 600; alphav = 5/100;
   low = round((alphav*nboot)/2); high = nboot - low;
   WP = W(:,1); WP = WP(randi(size(W,1),size(W,1),nboot));
   WC = W(:,2); WC = WC(randi(size(W,2),size(W,2),nboot));
   BP = B(:,1); BP = BP(randi(size(B,1),size(B,1),nboot));
   BC = B(:,2); BC = BC(randi(size(B,2),size(B,2),nboot));
   
   % mean 
   MWP = sort(mean(WP,1)); MWC = sort(mean(WC,1)); 
   Stats.CI.means_within(1,:) = [MWP(low)  MWC(low)];
   Stats.CI.means_within(2,:) = [MWP(high) MWC(high)];
   clear MWP MWC
   
   MBP = sort(mean(BP,1)); MBC = sort(mean(BC,1)); 
   Stats.CI.means_between(1,:) = [MBP(low)  MBP(low)];
   Stats.CI.means_between(2,:) = [MBP(high) MBP(high)];
   clear MBP MBC
   
   DP = sort(mean(WP,1))-sort(mean(BP,1)); 
   DC = sort(mean(WC,1))-sort(mean(BC,1)); 
   Stats.means_difference = mean(W,1)-mean(B,1);
   Stats.CI.means_difference(1,:) = [DP(low)  DC(low)];
   Stats.CI.means_difference(2,:) = [DP(high) DC(high)];
   pb = length(find(DP>0)) / nboot; 
   Stats.pval.means_difference(1) = 2*min(pb,1-pb);
   if Stats.pval.means_difference(1) == 0
       Stats.pval.means_difference(1) = 1/nboot;
   end
   pb = length(find(DC>0)) / nboot; 
   Stats.pval.means_difference(2) = 2*min(pb,1-pb);
   if Stats.pval.means_difference(2) == 0
       Stats.pval.means_difference(2) = 1/nboot;
   end
   clear DP DC
  
   % median 
   MWP = sort(median(WP,1)); MWC = sort(median(WC,1)); 
   Stats.CI.medians_within(1,:) = [MWP(low)  MWC(low)];
   Stats.CI.medians_within(2,:) = [MWP(high) MWC(high)];
   clear MWP MWC
   
   MBP = sort(median(BP,1)); MBC = sort(median(BC,1)); 
   Stats.CI.medians_between(1,:) = [MBP(low)  MBP(low)];
   Stats.CI.medians_between(2,:) = [MBP(high) MBP(high)];
   clear MBP MBC
   
   DP = sort(median(WP,1)-median(BP,1)); 
   DC = sort(median(WC,1)-median(BC,1)); 
   Stats.medians_difference = median(W)-median(B);
   Stats.CI.medians_difference(1,:) = [DP(low)  DC(low)];
   Stats.CI.medians_difference(2,:) = [DP(high) DC(high)];
   pb = length(find(DP>0)) / nboot; 
   Stats.pval.medians_difference = 2*min(pb,1-pb);
   if Stats.pval.medians_difference(1) == 0
       Stats.pval.medians_difference(1) = 1/nboot;
   end
   Stats.pval.medians_difference(2) = 2*min(pb,1-pb);
   if Stats.pval.medians_difference(2) == 0
       Stats.pval.medians_difference(2) = 1/nboot;
   end
   clear DP DC   
   
end





