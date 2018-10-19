function [D,CI] = compare_correlations(varargin)

% Percentile bootstrap to compare correlation coef.
%
% FORMAT: [D,CI] = compare_correlations(data1,data2,method,type)
%
% INPUT: data1 data from gp 1 - matrix n1*2
%        data2 data from gp 2 - matrix n2*2
%        method type of correlation to use 'Pearson' 'Spearman' 'bendcorr'
%        'Skipped_P' or 'Skipped_S' (for skipped corr Pearson or Spearman)
%        type=2 for independent case (default) or type=1 for apparied measures (then n1=n2)
%
% OUTPUT: D the observed difference
%         CI the 95% of the observed difference
%
% Cyril Pernet v1 08 April 2013

%% input checks

if nargin<3
    error('not enough argument');
end

names{1} = 'Pearson';
names{2} = 'Spearman';
names{3} = 'bendcorr';
names{4} = 'Skipped_P';
names{5} = 'Skipped_S';

if nargin == 3
    type = 2;
else
    type = varargin{4};
end

if type == 1
    if sum((size(varargin{1})==size(varargin{2}))) ~=2
        error('for paired data, data1 and data2 must have the same size')
    end
end
data1 = varargin{1};
data2 = varargin{2};

method = varargin{3};
if isempty(cell2mat(strfind(names,method)))
    error('unknown method choose between ''Pearson'' ''Spearman'' ''bendcorr'' ''Skipped_P'' ''Skipped_S''');
end

%% bootstrap
nboot = 600;
low = round((5/100*nboot)/2);
high = nboot - low;

switch type
    case {1}  % dependent groups
        % boostrap data
        table= randi(size(data,1),size(data1,1),599);
        X1 = data1(:,1); X1 = X1(table);
        Y1 = data1(:,2); Y1 = Y1(table);
        X2 = data2(:,1); X2 = X2(table);
        Y2 = data2(:,2); Y2 = Y2(table);
        
        for b=1:nboot
            if strcmp(method,names{1})
                D = Pearson(data1(:,1),data1(:,2),0) - Pearson(data2(:,1),data2(:,2),0);
                r1 = Pearson(X1,Y1,0);
                r2 = Pearson(X2,Y2,0);
                
            elseif strcmp(method,names{2})
                D = Spearman(data1(:,1),data1(:,2),0) - Spearman(data2(:,1),data2(:,2),0);
                r1 = Spearman(X1,Y1,0);
                r2 = Spearman(X2,Y2,0);
            elseif strcmp(method,names{3})
                D = bendcorr(data1(:,1),data1(:,2),0) - bendcorr(data2(:,1),data2(:,2),0);
                r1 = bendcorr(X1,Y1,0);
                r2 = bendcorr(X2,Y2,0);
            else
                if strcmp(method,names{4}), estimator = 'Pearson';
                else estimator = 'Spearman'; end
                D = skipped_correlation(data1(:,1),data1(:,2),0,estimator) - skipped_correlation(data2(:,1),data2(:,2),0,estimator);
                r1 = skipped_correlation(X1,Y1,0,estimator);
                r2 = skipped_correlation(X2,Y2,0,estimator);
            end
        end
        
        d = sort(r1-r2);
        CI = [d(low) d(high)];
        
    case {2}  % independent groups
        % boostrap data
        n1 = size(data1,1); table1= randi(n1,n1,599);
        X1 = data1(:,1); X1 = X1(table1);
        Y1 = data1(:,2); Y1 = Y1(table1);
        
        n2 = size(data2,1); table2= randi(n2,n2,599);
        X2 = data2(:,1); X2 = X2(table2);
        Y2 = data2(:,2); Y2 = Y2(table2);
        
        for b=1:nboot
            if strcmp(method,names{1})
                D = Pearson(data1(:,1),data1(:,2),0) - Pearson(data2(:,1),data2(:,2),0);
                r1 = Pearson(X1,Y1,0);
                r2 = Pearson(X2,Y2,0);
                
                % adjust percentile following Wilcox 2012
                N  = n1+n2;
                if N<40
                    low = 7; high = 593;
                elseif N>=40 && N<80
                    low = 8; high = 592;
                elseif N>=80 && N<180
                    low = 11; high = 588;
                elseif N>=180 && N<250
                    low = 14; high = 585;
                elseif N>=250
                    low = 15; high = 584;
                end
                
            elseif strcmp(method,names{2})
                D = Spearman(data1(:,1),data1(:,2),0) - Spearman(data2(:,1),data2(:,2),0);
                r1 = Spearman(X1,Y1,0);
                r2 = Spearman(X2,Y2,0);
            elseif strcmp(method,names{3})
                D = bendcorr(data1(:,1),data1(:,2),0) - bendcorr(data2(:,1),data2(:,2),0);
                r1 = bendcorr(X1,Y1,0);
                r2 = bendcorr(X2,Y2,0);
            else
                if strcmp(method,names{4}), estimator = 'Pearson';
                else estimator = 'Spearman'; end
                D = skipped_correlation(data1(:,1),data1(:,2),0,estimator) - skipped_correlation(data2(:,1),data2(:,2),0,estimator);
                r1 = skipped_correlation(X1,Y1,0,estimator);
                r2 = skipped_correlation(X2,Y2,0,estimator);
            end
        end
        
        d = sort(r1-r2);
        CI = [d(low) d(high)];
end




