function obj = corConcordance(obj,crObj)

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
    [VecX,VecY,XLabel,YLabel,sig] = qmrstat.getBivarCorInputs(obj,curObj,curObj(1).LabelIdx(zz));

else
    % If mask is binary, then index won't be passed.
    [VecX,VecY,XLabel,YLabel,sig] = qmrstat.getBivarCorInputs(obj,curObj);

end

if strcmp(crObj(1).FigureOption,'osd')

  [rC,biasFactorC,hboot,CI] = Concordance(VecX,VecY,XLabel,YLabel,1,sig);

elseif strcmp(crObj(1).FigureOption,'save')

  [rC,biasFactorC,hboot,CI,h] = Concordance(VecX,VecY,XLabel,YLabel,1,sig);
  obj.Results.Correlation(zz,kk).Concordance.figure = h;

  if lbIdx>1

  obj.Results.Correlation(zz,kk).Concordance.figLabel = [XLabel '_' YLabel '_' curObj(1).StatLabels(zz)];

  else

  obj.Results.Correlation(zz,kk).Concordance.figLabel = [XLabel '_' YLabel];

  end

elseif strcmp(crObj(1).FigureOption,'disable')

  [rC,biasFactorC,hboot,CI] = Concordance(VecX,VecY,XLabel,YLabel,0,sig);


end

% Corvis is assigned to caller (qmrstat.Pearson) workspace by
% the Pearson function.
% Other fields are filled by Pearson function.

if obj.Export2Py

  PyVis.XData = VecX;
  PyVis.YData = VecY;
  PyVis.Stats.r = rC;
  PyVis.Stats.bias = biasFactorC;
  PyVis.Stats.hboot = hboot;
  PyVis.Stats.CI = CI;
  PyVis.XLabel = XLabel;
  PyVis.YLabel = YLabel;
  obj.Results.Correlation(zz,kk).Concordance.PyVis = PyVis;

end


obj.Results.Correlation(zz,kk).Concordance.r = rC;
obj.Results.Correlation(zz,kk).Concordance.bias = biasFactorC;
obj.Results.Correlation(zz,kk).Concordance.hboot = hboot;
obj.Results.Correlation(zz,kk).Concordance.CI = CI;
end
