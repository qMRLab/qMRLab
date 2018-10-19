function [rs,ts,CI,pval,outid,h]=skipped_Spearman(varargin)
%SKIPPED_SPEARMAN Spearman correlation after bivariate outlier removal
%
% performs a robust Spearman correlation on data cleaned up for bivariate outliers,
% that is after finding the central point in the distribution using the mid covariance
% determinant, orthogonal distances are computed to this point, and any data outside the
% bound defined by the idealf estimator of the interquartile range is removed.
%
% FORMAT: [rp,tp,CI,pval,outid,h]=skipped_Spearman(X,pairs,method,alphav,p_alpha);
%
% INPUTS:  X is a matrix and correlations between all pairs (default) are computed
%          pairs (optional) is a n*2 matrix of pairs of columns to correlate
%          method (optional) is 'ECP' or 'Hochberg' (only for n>60)
%          alphav (optional, 5% by default) is the requested alpha level
%          p_alpha (optional) the critical p_value to correct for multiple
%                  comparisons (see MC_corrpval)
%
% OUTPUTS: rs is the Spearman correlation
%          ts is the T value associated to the skipped correlation
%          CI is the robust confidence interval of r computed by bootstrapping
%             the cleaned-up data set and taking the alphav centile values
%          pval is the p value associated to t
%          outid is the index of bivariate outliers
%          h is the significance after correction for multiple comparisons
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
%
% Cyril Pernet v3 - Novembre 2017
% ---------------------------------------------------
%  Copyright (C) Corr_toolbox 2017

%% check the data input

% _if no input simply return the help, otherwise load the data X_
if nargin <1
    help skipped_Spearman
    return
else
    x = varargin{1};
    [n,p]=size(x);
end

% _set the default options_
method   = 'ECP';
alphav   = 5/100;
pairs    = nchoosek([1:p],2);
nboot    = 599;

% _check other inputs of the function_
for inputs = 2:nargin
    if inputs     == 2
        pairs    = varargin{inputs};
    elseif inputs == 3
        method   = varargin{inputs};
    elseif inputs == 4
        alphav   = varargin{inputs};
    elseif inputs == 5
        p_alpha = varargin{inputs};
    end
end

% _do a quick quality check_
if isempty(pairs)
    pairs = nchoosek([1:p],2);
end

if size(pairs,2)~=2
    pairs = pairs';
end

if sum(strcmpi(method,{'ECP','Hochberg'})) == 0
    error('unknown method selected, see help skipped_Spearman')
end

if strcmp(method,'Hochberg') && n<60 || strcmp(method,'Hochberg') && n<60 && alphav == 5/100
    error('Hochberg is only valid for n>60 and aplha 5%')
end

%% start the algorithm

% _create a table of resamples_
if nargout > 2
  boot_index = 1;
  while boot_index <= nboot
      resample = randi(n,n,1);
      if length(unique(resample)) > 3 % at least 3 different data points
          boostrap_sampling(:,boot_index) = resample;
          boot_index = boot_index +1;
      end
  end
  lower_bound = round((alphav*nboot)/2);
  upper_bound = nboot - lower_bound;
end

% now for each pair to test, get the observed and boostrapped r and t
% values, then derive the p value from the bootstrap (and hboot and CI if
% requested)

% place holders
rs    = NaN(size(pairs,1),1);
for outputs = 2:nargout
    if outputs == 2
    ts    = NaN(size(pairs,1),1);
elseif outputs == 3
  CI = NaN(size(pairs,1),2);
elseif outputs == 4
  pval  = NaN(size(pairs,1),1);
elseif outputs == 5
  outid = cell(size(pairs,1),1);
end

% loop for each pair to test
for row = 1:size(pairs,1)

    % select relevant columns
    X = [x(:,pairs(row,1)) x(:,pairs(row,2))];
    % get the bivariate outliers
    flag = bivariate_outliers(X);
    vec = 1:n;
    if sum(flag)==0
        outid{row}=[];
    else
        flag=(flag>=1);
        outid{row}=vec(flag);
    end
    keep=vec(~flag); % the vector of data to keep

    % Spearman correlation on cleaned data
    xrank = tiedrank(X(keep,1),0); yrank = tiedrank(X(keep,2),0);
    rs(row) = sum(detrend(xrank,'constant').*detrend(yrank,'constant')) ./ ...
        (sum(detrend(xrank,'constant').^2).*sum(detrend(yrank,'constant').^2)).^(1/2);
    ts(row) = rs(row)*sqrt((n-2)/(1-rs(row).^2));

    if nargout > 2
        % redo this for bootstrap samples
        % fprintf('computing p values by bootstrapping data, pair %g %g\n',pairs(row,1),pairs(row,2))
        parfor b=1:nboot
            Xb = X(boostrap_sampling(:,b),:);
            xrank = tiedrank(Xb(keep,1),0); yrank = tiedrank(Xb(keep,2),0);
            r(b) = sum(detrend(xrank,'constant').*detrend(yrank,'constant')) ./ ...
                (sum(detrend(xrank,'constant').^2).*sum(detrend(yrank,'constant').^2)).^(1/2);
        end

        % get the CI
        r = sort(r);
        CI(row,:) = [r(lower_bound) r(upper_bound)];

        % get the p value
        Q = sum(r<0)/nboot;
        pval(row) = 2*min([Q 1-Q]);
    end
end


%% once we have all the r and t values, we need to adjust for multiple comparisons
if nargout == 6
    if strcmp(method,'ECP')
        if exist('p_alpha','var')
            h = pval < p_alpha;
        else
            disp('ECP method requested, computing p alpha ... (takes a while)')
            p_alpha = MC_corrpval(n,p,'Skipped Spearman',alphav,pairs);
            h = pval < p_alpha;
        end
    elseif strcmp(method,'Hochberg')
        [sorted_pval,index] = sort(pval,'descend');
        [~,reversed_index]=sort(index);
        k = 1; sig = 0; h = zeros(1,length(pval));
        while sig == 0
            if sorted_pval(k) <= alphav/k
                h(k:end) = 1; sig = 1;
            else
                k = k+1;
                if k == length(h)
                    break
                end
            end
        end
        h = h(reversed_index);

        %% quick clean-up of individual p-values
        pval(pval==0) = 1/nboot;end

end

disp('Skipped Spearman done')
