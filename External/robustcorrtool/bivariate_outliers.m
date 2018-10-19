function flag = bivariate_outliers(X)

% routine that find the bivariate outliers using orthogonal projection and
% box plot rule 

% find the centre of the data cloud using mid-covariance determinant
n   = size(X,1);
result = mcdcov(X,'cor',1,'plots',0,'h',floor((n+size(X,2)*2+1)/2));
center = result.center;

% orthogonal projection to the lines joining the center
% followed by outlier detection using box plot rule

gval = sqrt(chi2inv(0.975,2)); % in fact depends on size(X,2) but here always = 2
for i=1:n % for each row
    dis = NaN(n,1);
    B   = (X(i,:)-center)';
    BB  = B.^2;
    bot = sum(BB);
    if bot~=0
        for j=1:n
            A = (X(j,:)-center)';
            dis(j)= norm(A'*B/bot.*B);
        end
        % IQR rule
        [ql,qu]=idealf(dis);
        record{i} = (dis > median(dis)+gval.*(qu-ql)) ; % + (dis < median(dis)-gval.*(qu-ql));
    end
end

try
    flag = nan(n,1);
    flag = sum(cell2mat(record),2); % if any point is flagged
    
catch ME  % this can happen to have an empty cell so loop
    flag = nan(n,size(record,2));
    index = 1;
    for s=1:size(record,2)
        if ~isempty(record{s})
            flag(:,index) = record{s};
            index = index+1;
        end
    end
    flag(:,index:end) = [];
    flag = sum(flag,2);
end

