function obj = corPrcntgBend(obj,crObj)
% Developers: * qmrstat.getBivarCorInputs (Static)
%               -- calls qmrstat.getBiVarCorVec (Private)
%               ---- calls qmrstat.cleanNan (Private)
%             * Pearson (External/robustcorrtool)

% getBivarCorInputs includes validation step. Validation step
% is not specific to the object arrays with 2 objects. N>2 can
% be also validated by qmrstat.validate (private).

% Fixed bend percent to 0.2

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

if strcmp(crObj(1).FigureOption,'osd')

  [r,t,p,hboot,CI,~,~] = bendcorr(VecX,VecY,XLabel,YLabel,1,0.2);

elseif strcmp(crObj(1).FigureOption,'save')

  [r,t,p,hboot,CI,~,~,hout] = bendcorr(VecX,VecY,XLabel,YLabel,1,0.2);
   obj.Results.Correlation(zz,kk).Bend.figure = hout;

   if lbIdx>1

  obj.Results.Correlation(zz,kk).Bend.figLabel = [XLabel '_' YLabel '_' curObj(1).StatLabels(zz)];

  else

  obj.Results.Correlation(zz,kk).Bend.figLabel = [XLabel '_' YLabel];

   end

elseif strcmp(crObj(1).FigureOption,'disable')


  [r,t,p,hboot,CI,~,~] = bendcorr(VecX,VecY,XLabel,YLabel,0,0.2);

end


if obj.Export2Py

  PyVis.XLabel = XLabel;
  PyVis.YLabel = YLabel;
  PyVis.Stats.r = r;
  PyVis.Stats.t = t;
  PyVis.Stats.p = p;
  PyVis.Stats.hboot = hboot;
  PyVis.Stats.CI = CI;
  obj.Results.Correlation(zz,kk).Bend.PyVis = PyVis;

end


obj.Results.Correlation(zz,kk).Bend.r = r;
obj.Results.Correlation(zz,kk).Bend.t = t;
obj.Results.Correlation(zz,kk).Bend.hboot = hboot;
obj.Results.Correlation(zz,kk).Bend.CI = CI;
obj.Results.Correlation(zz,kk).Bend.p = p;
end
end
