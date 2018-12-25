function Correlation = corPearson(obj,crObj)
%Explain for user here.

% Developers: * qmrstat.getBivarCorInputs (Static)
%               -- calls qmrstat.getBiVarCorVec (Private)
%               ---- calls qmrstat.cleanNan (Private)
%             * Pearson (External/robustcorrtool)

% getBivarCorInputs includes validation step. Validation step
% is not specific to the object arrays with 2 objects. N>2 can
% be also validated by qmrstat.validate (private).

% Uniformity assumptions for qmrstat_correlation objects here:
% LabelIdx
% StatLabels
% BOTH FIELDS ARE REQUIRED



if nargin<2

  crObj = obj.Object.Correlation;

elseif nargin == 2

  obj.Object.Correlation = crObj;

end

[comb, lbIdx, sig] = qmrstat.corInit(crObj);
crObj = crObj.setSignificanceLevel(sig);

szcomb = size(comb);

Correlation = repmat(struct(), [lbIdx szcomb(1)]);
for kk = 1:szcomb(1) % Loop over correlation matrix combinations
for zz = 1:lbIdx % Loop over labeled mask indexes (if available)

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

  [r,t,pval,hboot,CI] = Pearson(VecX,VecY,XLabel,YLabel,1,sig);
  
  if lbIdx>1
   
      svds.Tag.SegmentID = curObj(1).StatLabels(zz);
      
  end

elseif strcmp(crObj(1).FigureOption,'save')

  [r,t,pval,hboot,CI,Correlation(zz,kk).figure] = ...
      Pearson(VecX,VecY,XLabel,YLabel,1,sig);
  
  
  if lbIdx>1
  
  Correlation(zz,kk).figLabel = [XLabel '_' YLabel '_' num2str(curObj(1).StatLabels{zz})];
  % Attach segment ID only if labels are available. 
  svds.Tag.SegmentID = curObj(1).StatLabels(zz);
  
  else

  Correlation(zz,kk).figLabel = [XLabel '_' YLabel];

  end

elseif strcmp(crObj(1).FigureOption,'disable')


  [r,t,pval,hboot,CI] = Pearson(VecX,VecY,XLabel,YLabel,0,sig);

end

% Developer: 
% svds is assigned to caller (qmrstat.Pearson) workspace by
% the Pearson function.
% Other fields are filled out here below. 

if obj.Export2Py
  
  svds.Tag.Class = 'Bivariate::Pearson';
  svds.Required.xData = VecX';
  svds.Required.yData = VecY';
  svds.Required.rPearson = r;
  svds.Required.xLabel = XLabel';
  svds.Required.yLabel = YLabel';
  
  svds.Optional.pval = pval;
  svds.Optional.h = hboot;
  
  if not(isempty(CI))
    svds.Optional.CI = CI';
    Correlation(zz,kk).CI = CI;
  end

    Correlation(zz,kk).SVDS = svds;

end


Correlation(zz,kk).r = r;
Correlation(zz,kk).t = t;
Correlation(zz,kk).pval =  pval;
Correlation(zz,kk).hboot = hboot;
 

end
end % loop

end % Correlation

