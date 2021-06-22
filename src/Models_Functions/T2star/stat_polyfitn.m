function polymodel = stat_polyfitn(indepvar,depvar,modelterms)
% polyfitn: fits a general polynomial regression model in n dimensions
% usage: polymodel = polyfitn(indepvar,depvar,modelterms)
%
% Polyfitn fits a polynomial regression model of one or more
% independent variables, of the general form:
%
%   z = f(x,y,...) + error
%
% arguments: (input)
%  indepvar - (n x p) array of independent variables as columns
%        n is the number of data points
%        p is the dimension of the independent variable space
%
%        IF n == 1, then I will assume there is only a
%        single independent variable.
%
%  depvar   - (n x 1 or 1 x n) vector - dependent variable
%        length(depvar) must be n.
%
%        Only 1 dependent variable is allowed, since I also
%        return statistics on the model.
%
%  modelterms - defines the terms used in the model itself
%
%        IF modelterms is a scalar integer, then it designates
%           the overall order of the model. All possible terms
%           up to that order will be employed. Thus, if order
%           is 2 and p == 2 (i.e., there are two variables) then
%           the terms selected will be:
%
%              {constant, x, x^2, y, x*y, y^2}
%
%           Beware the consequences of high order polynomial
%           models.
%
%        IF modelterms is a (k x p) numeric array, then each
%           row of this array designates the exponents of one
%           term in the model. Thus to designate a model with
%           the above list of terms, we would define modelterms as
%           
%           modelterms = [0 0;1 0;2 0;0 1;1 1;0 2]
%
%        If modelterms is a character string, then it will be
%           parsed as a list of terms in the regression model.
%           The terms will be assume to be separated by a comma
%           or by blanks. The variable names used must be legal
%           matlab variable names. Exponents in the model may
%           may be any real number, positive or negative.
%
%           For example, 'constant, x, y, x*y, x^2, x*y*y'
%           will be parsed as a model specification as if you
%           had supplied:
%           modelterms = [0 0;1 0;0 1;1 1;2 0;1 2]
%           
%           The word 'constant' is a keyword, and will denote a
%           constant terms in the model. Variable names will be
%           sorted in alphabetical order as defined by sort.
%           This order will assign them to columns of the
%           independent array. Note that 'xy' will be parsed as
%           a single variable name, not as the product of x and y.
%
%        If modelterms is a cell array, then it will be taken
%           to be a list of character terms. Similarly,
%           
%           {'constant', 'x', 'y', 'x*y', 'x^2', 'x*y^-1'}
%
%           will be parsed as a model specification as if you
%           had supplied:
%
%           modelterms = [0 0;1 0;0 1;1 1;2 0;1 -1]
%
% Arguments: (output)
%  polymodel - A structure containing the regression model
%        polymodel.ModelTerms = list of terms in the model
%        polymodel.Coefficients = regression coefficients
%        polymodel.ParameterVar = variances of model coefficients
%        polymodel.ParameterStd = standard deviation of model coefficients
%        polymodel.R2 = R^2 for the regression model
%        polymodel.RMSE = Root mean squared error
%        polymodel.VarNames = Cell array of variable names
%           as parsed from a char based model specification.
%  
%        Note 1: Because the terms in a general polynomial
%        model can be arbitrarily chosen by the user, I must
%        package the erms and coefficients together into a
%        structure. This also forces use of a special evaluation
%        tool: polyvaln.
%
%        Note 2: A polymodel can be evaluated for any set
%        of values with the function polyvaln. However, if
%        you wish to manipulate the result symbolically using
%        my own sympoly tools, this structure can be converted
%        to a sympoly using the function polyn2sympoly.
%
%        Note 3: When no constant term is included in the model,
%        the traditional R^2 can be negative. This case is
%        identified, and then a more appropriate computation
%        for R^2 is then used.
%
% Find my sympoly toolbox here:
% http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=9577&objectType=FILE
%
% See also: polyvaln, polyfit, polyval, polyn2sympoly, sympoly
%
% Author: John D'Errico
% Release: 2.0
% Release date: 2/19/06

if nargin<1
  help polyfitn
  return
end

% get sizes, test for consistency
[n,p] = size(indepvar);
if n == 1
  indepvar = indepvar';
  [n,p] = size(indepvar);
end
[m,q] = size(depvar);
if m == 1
  depvar = depvar';
  [m,q] = size(depvar);
end
% only 1 dependent variable allowed at a time
if q~=1
  error 'Only 1 dependent variable allowed at a time.'
end

if n~=m
  error 'indepvar and depvar are of inconsistent sizes.'
end

% Automatically scale the independent variables to unit variance
stdind = sqrt(diag(cov(indepvar)));
if any(stdind==0)
  warning 'Constant terms in the model must be entered using modelterms'
  stdind(stdind==0) = 1;
end
% scaled variables
indepvar_s = indepvar*diag(1./stdind);

% do we need to parse a supplied model?
if iscell(modelterms) || ischar(modelterms)
  [modelterms,varlist] = parsemodel(modelterms,p);
  if size(modelterms,2) < p
    modelterms = [modelterms, zeros(size(modelterms,1),p - size(modelterms,2))];
  end  
elseif length(modelterms) == 1
  % do we need to generate a set of modelterms?
  [modelterms,varlist] = buildcompletemodel(modelterms,p);
elseif size(modelterms,2) ~= p
  error 'ModelTerms must be a scalar or have the same # of columns as indepvar'
end
nt = size(modelterms,1);

% check for replicate terms 
if nt>1
  mtu = unique(modelterms,'rows');
  if size(mtu,1)<nt
    warning 'Replicate terms identified in the model.'
  end
end

% build the design matrix
M = ones(n,nt);
scalefact = ones(1,nt);
for i = 1:nt
  for j = 1:p
    M(:,i) = M(:,i).*indepvar_s(:,j).^modelterms(i,j);
    scalefact(i) = scalefact(i)/(stdind(j)^modelterms(i,j));
  end
end

% estimate the model using QR. do it this way to provide a
% covariance matrix when all done. Use a pivoted QR for
% maximum stability.
[Q,R,E] = qr(M,0);

polymodel.ModelTerms = modelterms;
polymodel.Coefficients(E) = R\(Q'*depvar);
yhat = M*polymodel.Coefficients(:);

% recover the scaling
polymodel.Coefficients=polymodel.Coefficients.*scalefact;

% variance of the regression parameters
s = norm(depvar - yhat);
if n > nt
  Rinv = R\eye(nt);
  Var(E) = s^2*sum(Rinv.^2,2)/(n-nt);
  polymodel.ParameterVar = Var.*(scalefact.^2);
  polymodel.ParameterStd = sqrt(polymodel.ParameterVar);
else
  % we cannot form variance or standard error estimates
  % unless there are at least as many data points as
  % parameters to estimate.
  polymodel.ParameterVar = inf(1,nt);
  polymodel.ParameterStd = inf(1,nt);
end

% R^2
% is there a constant term in the model? If not, then
% we cannot use the standard R^2 computation, as it
% frequently yields negative values for R^2.
if any((M(1,:) ~= 0) & all(diff(M,1,1) == 0,1))
  %we have a constant term in the model, so the
  % traditional %R^2 form is acceptable.
  polymodel.R2 = max(0,1 - (s/norm(depvar-mean(depvar)) )^2);
else
  % no constant term was found in the model
  polymodel.R2 = max(0,1 - (s/norm(depvar))^2);
end

% RMSE
polymodel.RMSE = sqrt(mean((depvar - yhat).^2));

% if a character 'model' was supplied, return the list
% of variables as parsed out
if exist('varlist')
	polymodel.VarNames = varlist;
end

% ==================================================
% =============== begin subfunctions ===============
% ==================================================
function [modelterms,varlist] = buildcompletemodel(order,p)
% 
% arguments: (input)
%  order - scalar integer, defines the total (maximum) order 
%
%  p     - scalar integer - defines the dimension of the
%          independent variable space
%
% arguments: (output)
%  modelterms - exponent array for the model
%
%  varlist - cell array of character variable names

% build the exponent array recursively
if p == 0
  % terminal case
  modelterms = [];
elseif (order == 0)
  % terminal case
  modelterms = zeros(1,p);
elseif (p==1)
  % terminal case
  modelterms = (order:-1:0)';
else
  % general recursive case
  modelterms = zeros(0,p);
  for k = order:-1:0
    t = buildcompletemodel(order-k,p-1);
    nt = size(t,1);
    modelterms = [modelterms;[repmat(k,nt,1),t]];
  end
end

% create a list of variable names for the variables on the fly
varlist = cell(1,p);
for i = 1:p
  varlist{i} = ['X',num2str(i)];
end


% ==================================================
function [modelterms,varlist] = parsemodel(model,p);
% 
% arguments: (input)
%  model - character string or cell array of strings
%
%  p     - number of independent variables in the model
%
% arguments: (output)
%  modelterms - exponent array for the model

modelterms = zeros(0,p);
if ischar(model)
  model = deblank(model);
end

varlist = {};
while ~isempty(model)
  if iscellstr(model)
    term = model{1};
    model(1) = [];
  else
    [term,model] = strtok(model,' ,');
  end
  
  % We've stripped off a model term. Now parse it.
  
  % Is it the reserved keyword 'constant'?
  if strcmpi(term,'constant')
    modelterms(end+1,:) = 0;
  else
    % pick this term apart
    expon = zeros(1,p);
    while ~isempty(term)
      vn = strtok(term,'*/^. ,');
      k = find(strncmp(vn,varlist,length(vn)));
      if isempty(k)
        % its a variable name we have not yet seen
        
        % is it a legal name?
        nv = length(varlist);
        if ismember(vn(1),'1234567890_')
          error(['Variable is not a valid name: ''',vn,''''])
        elseif nv>=p
          error 'More variables in the model than columns of indepvar'
        end
        
        varlist{nv+1} = vn;
        
        k = nv+1;
      end
      % variable must now be in the list of vars. 
      
      % drop that variable from term
      i = strfind(term,vn);
      term = term((i+length(vn)):end);
      
      % is there an exponent?
      eflag = false;
      if strncmp('^',term,1)
        term(1) = [];
        eflag = true;
      elseif strncmp('.^',term,2)
        term(1:2) = [];
        eflag = true;
      end

      % If there was one, get it
      ev = 1;
      if eflag
        ev = sscanf(term,'%f');
        if isempty(ev)
            error 'Problem with an exponent in parsing the model'
        end
      end
      expon(k) = expon(k) + ev;

      % next monomial subterm?
      k1 = strfind(term,'*');
      if isempty(k1)
        term = '';
      else
        term(k1(1)) = ' ';
      end
      
    end
  
    modelterms(end+1,:) = expon;  
    
  end
  
end

% Once we have compiled the list of variables and
% exponents, we need to sort them in alphabetical order
[varlist,tags] = sort(varlist);
modelterms = modelterms(:,tags);