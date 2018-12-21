function obj = corInspect(obj,crObj)

if nargin<2

 crObj = obj.Object.Correlation;

elseif nargin == 2

 obj.Object.Correlation = crObj;

end

[comb, lbIdx] = qmrstat.corSanityCheck(crObj);

szcomb = size(comb);
for kk = 1:szcomb(1) % Loop over correlation matrix combinations
for zz = 1:lbIdx % Loope over labeled mask indexes (if available)

% Combine pairs
curObj = [crObj(1,comb(kk,1)),crObj(1,comb(kk,2))];

if lbIdx >1

   % If mask is labeled, masking will be done by the corresponding
   % index, if index is passed as the third parameter.
   [VecX,VecY,XLabel,YLabel,~] = qmrstat.getBivarCorInputs(obj,curObj,curObj(1).LabelIdx(zz));

else
   % If mask is binary, then index won't be passed.
   [VecX,VecY,XLabel,YLabel,~] = qmrstat.getBivarCorInputs(obj,curObj);

end

% Univariate histograms, scatterplot, and joint histogram
h1 = corr_normplot(VecX,VecY,XLabel,YLabel);

% Joint density histogram. Bivariate distributions show how
% they behave together.

[h2,density] = joint_density(VecX,VecY,XLabel,YLabel);



% By collapsing over the opposite variable, it is also possible
% to see how X or y behave separately. However, this is
% diffeerent than looking at two univariate distributions. Instead,
% such observetion (collapsing one over another) becomes
% conditinal.

% Below function tests heteroscedasticity based on conditional
% variances of the input pairs, where the conditional
% expectation of x given y and y given x is calculated based on
% Pearson's r.

% Check if distributions are heteroscedastic.

[hetcedas, CI] = variance_homogeneity(VecX,VecY,1);


obj.Results.Correlation(zz,kk).PreInspect.figures.histograms = h1;
obj.Results.Correlation(zz,kk).PreInspect.figures.jointDensity = h2;
obj.Results.Correlation(zz,kk).PreInspect.density = density;
obj.Results.Correlation(zz,kk).PreInspect.heteroscedasticity.CI = CI;

% Independent variables are uncorrelated. But uncorrelated
% variables does not ensure that they are independent.
% Bivariate normality must be controlled.

% If two variables show joint normality and they are not
% correlated, this means that they are independent.
% Henze- Zirkler test for bivariate normality

[jointNormality.test_value,jointNormality.p_value] = ...
HZmvntest(VecX,VecY,5/100);




% Seems counterintuitive at first sight, (significant when pval
% is bigger than threshold). But this is the case with
% HZmnvtest. See HZmnvtest line 249.

if jointNormality.p_value >= 5/100

 JointNormality = {'true'};
else
 JointNormality = {'false'};
end

if hetcedas==1
 Heteroscedasticity = {'true'};
else
 Heteroscedasticity = {'false'};
end

comp = [VecX(:,1) VecY(:,1)];
flag = bivariate_outliers(comp);
BiVarOutliers = length(find(flag~=0));

 t = table(BiVarOutliers,JointNormality,Heteroscedasticity);
 if lbIdx>1

 disp([cell2mat(XLabel) '_' cell2mat(YLabel) ' at:' cell2mat(curObj(1).StatLabels(zz))]);

 else

 disp([cell2mat(XLabel) '_' cell2mat(YLabel)]);

 end

disp(t);
obj.Results.Correlation(zz,kk).PreInspect.table = t;
end
end
