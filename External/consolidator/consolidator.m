function [xcon,ycon,ind] = consolidator(x,y,aggregation_mode,tol)
% consolidator: consolidate "replicates" in x, also aggregate corresponding y
% usage: [xcon,ycon,ind] = consolidator(x,y,aggregation_mode,tol)
%
% arguments: (input)
%  x - rectangular array of data to be consolidated. If multiple (p)
%      columns, then each row of x is interpreted as a single point in a
%      p-dimensional space. (x may be character, in which case xcon will
%      be returned as a character array.)
%
%      x CANNOT be complex. If you do have complex data, split it into
%      real and imaginary components as columns of an array.
%
%      If x and y are both ROW vctors, they will be transposed and
%      treated as single columns.
%
%  y - outputs to be aggregated. If y is not supplied (is left empty)
%      then consolidator is similar to unique(x,'rows'), but with a
%      tolerance on which points are distinct. (y may be complex.)
%
%      y MUST have the same number of rows as x unless y is empty.
%
%  aggregation_mode - (OPTIONAL) - an aggregation function, either
%      in the form of a function name, such as 'mean' or 'sum', or as
%      a function handle, i.e., @mean or @std. An inline function would
%      also work, for those users of older matlab releases.
%
%      DEFAULT: 'mean'
%
%      Aggregation_mode may also be the string 'count', in which case
%      a count is made of the replicates found. Ycon will only have
%      one column in this case.
%      
%      The function supplied MUST have the property that it operates
%      on the the first dimension of its input by default.
%
%      Common functions one might use here are:
%      'mean', 'sum', 'median', 'min', 'max', 'std', 'var', 'prod'
%      'geomean', 'harmmean'.
%
%      These last two examples would utilize the statistics toolbox,
%      however, these means can be generated using a function
%      handle easily enough if that toolbox is not available:
%
%      fun = @(x) 1./mean(1./x)        % harmonic mean
%      fun = @(x) exp(mean(log(x)))    % geometric mean
%
%  tol - (OPTIONAL) tolerance to identify replicate elements of x. If
%      x has multiple columns, then the same (absolute) tolerance is
%      applied to all columns of x.
%
%      DEFAULT: 0
%
% arguments: (output)
%  xcon - consolidated x. Replicates wthin the tolerance are removed.
%      if no y was specified, then consolidation is still done on x.
%
%  ycon - aggregated value as specified by the aggregation_mode.
%
%  ind  - vector - denotes the elements of the original array which
%      were consolidated into each element of the result.
%
%
% Example 1:
%
% Group means: (using a function handle for the aggregation)
%  x = round(rand(1000,1)*5);
%  y = x+randn(size(x));
%  [xg,yg] = consolidator(x,y,@mean);
%  [xg,yg]
%  ans =
%         0    0.1668
%    1.0000    0.9678
%    2.0000    2.0829
%    3.0000    2.9688
%    4.0000    4.0491
%    5.0000    4.8852
%
% Example 2:
%
% Group counts on x
%  x = round(randn(100000,1));
%  [xg,c] = consolidator(x,[],'count');
%  [xg,c]
%  ans =
%         -4          26
%         -3         633
%         -2        5926
%         -1       24391
%          0       38306
%          1       24156
%          2        5982
%          3         559
%          4          21
%
% Example 3:
%
% Unique(x,'rows'), but with a tolerance
%  x = rand(100,2);
%  xc = consolidator(x,[],[],.05);
%  size(xc)
%  ans =
%      62     2
%
% See also: unique
%
% Author: John D'Errico
% e-mail address: woodchips@rochester.rr.com
% Release: 3
% Release date: 5/2/06

% is it a character array?
if ischar(x)
  charflag = 1;
  x=double(x);
else
  charflag = 0;
end

% check for/supply defaults
if (nargin<4) || isempty(tol)
  tol = 0;
end
if (tol<0)
  error 'Tolerance must be non-negative.'
end
tol = tol*(1+10*eps);

% -------------------------------------------------------
% DETERMINE AGGREGATION MODE AND CREATE A FUNCTION HANDLE
% -------------------------------------------------------
if (nargin < 3) || isempty(aggregation_mode)
 	% use default function
  fun=@mean;
  aggregation_mode='mean';
  
elseif ischar(aggregation_mode)
	aggregation_mode=lower(aggregation_mode);

  k=strmatch(aggregation_mode,'count');
  if ~isempty(k)
    fun=@(x) x;
	else
		fun=str2func(aggregation_mode);
  end
  
elseif isa(aggregation_mode,'inline')
  fun=aggregation_mode;
  am = struct(fun);
  aggregation_mode=am.expr;
  
else
  fun=aggregation_mode;
  aggregation_mode=func2str(fun);
  
end
% -------------------------------------------------------

% was y supplied, or empty?
[n,p] = size(x);
if (nargin<2) || isempty(y)
  y = zeros(n,0);
  fun = @(x) x;
  aggregation_mode = 'count';
end
% check for mismatch between x and y
[junk,q] = size(y);
if n~=junk
  error 'y must have the same number of rows as x.'
end

% are both x and y row vectors?
if (n == 1)
  x=x';
  n = length(x);
  p = 1;
  
  if ~isempty(y)
    y=y';
  else
    y=zeros(n,0);
  end
  
  q = size(y,2);
end

if isempty(y)
  aggregation_mode = 'count';
end

% consolidate elements of x.
% first shift, scale, and then ceil. 
if tol>0
  xhat = x - repmat(min(x,[],1),n,1)+tol*eps;
  xhat = ceil(xhat/tol);
else
  xhat = x;
end
[xhat,tags] = sortrows(xhat);
x=x(tags,:);
y=y(tags,:);

% count the replicates
iu = [true;any(diff(xhat),2)];
eb = cumsum(iu);

% which original elements went where?
if nargout>2
  ind = eb;
  ind(tags) = ind;
end

% count is the vector of counts for the consolidated
% x values
if issparse(eb)
  eb = full(eb);
end
count=accumarray(eb,1).';
% ec is the expanded counts, i.e., counts for the
% unconsolidated x
ec = count(eb);

% special case for aggregation_mode of 'count',
% but we still need to aggregate (using the mean) on x
if strcmp(aggregation_mode,'count')
  ycon = count.';
  q = 0;   % turn off aggregation on y
else
  ycon = zeros(length(count),q);
end

% loop over the different replicate counts, aggregate x and y
ucount = unique(count);
xcon = repmat(NaN,[length(count),p]);
fullx = ~issparse(x);
fully = ~issparse(y);
for k=ucount
  if k==1
    xcon(count==1,:) = x(ec==1,:);
  else
    if fullx
      v=permute(x(ec==k,:),[3 2 1]);
    else
      v=permute(full(x(ec==k,:)),[3 2 1]);
    end
    v=reshape(v,p,k,[]);
    v=permute(v,[2 1 3]);
    xcon(count==k,:)=reshape(mean(v),p,[]).';
  end
  
  if q>0
    % aggregate y as specified
    if k==1
      switch aggregation_mode
        case {'std' 'var'}
          ycon(count==1,:) = 0;
        otherwise
          ycon(count==1,:) = y(ec==1,:);
      end
    else
      if fully
        v=permute(y(ec==k,:),[3 2 1]);
      else
        v=permute(full(y(ec==k,:)),[3 2 1]);
      end
      v=reshape(v,q,k,[]);
      v=permute(v,[2 1 3]);
      
      % aggregate using the appropriate function
      ycon(count==k,:)=reshape(fun(v),q,[]).';
      
    end
  end
end

% was it originally a character array?
if charflag
  xcon=char(xcon);
end


