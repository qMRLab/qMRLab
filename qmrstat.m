classdef qmrstat

% ===============================================================

properties

Object

end

% ===============================================================

properties (Access = private)

CorrelationValid
CorrelationJointMask
MultipleCorrelation

Export2Py = false;
OutputDir

ReliabilityValid
ReliabilityJointMask
MultipleReliability

WarningHead = '-------------------------------- qMRLab Warning';
ErrorHead   = '----------------------------------------- qMRLab Error';
Tail = '\n-------------------------------------------------------|';




end

% ===============================================================

properties (SetAccess = private, GetAccess=public)

Results = struct();


end

% ===============================================================

% ===============================================================

methods


function obj = qmrstat()

  obj.Object.Correlation = qmrstat_correlation;
  obj.Object.Reliability = qmrstat_reliability;


end % Constructor  ------------------------ end (Public)

% ############################ ROBUST CORRELATION FAMILY

function obj = runCorPearson(obj,crObj)
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

    [r,t,pval,hboot,CI] = Pearson(VecX,VecY,XLabel,YLabel,1,sig);

  elseif strcmp(crObj(1).FigureOption,'save')

    [r,t,pval,hboot,CI,h] = Pearson(VecX,VecY,XLabel,YLabel,1,sig);
    obj.Results.Correlation(zz,kk).Pearson.figure = h;
    if lbIdx>1

    obj.Results.Correlation(zz,kk).Pearson.figLabel = [XLabel '_' YLabel '_' curObj(1).StatLabels(zz)];

    else
        
    obj.Results.Correlation(zz,kk).Pearson.figLabel = [XLabel '_' YLabel];    
    
    end
  
  elseif strcmp(crObj(1).FigureOption,'disable')


    [r,t,pval,hboot,CI] = Pearson(VecX,VecY,XLabel,YLabel,0,sig);

  end

  % Corvis is assigned to caller (qmrstat.Pearson) workspace by
  % the Pearson function.
  % Other fields are filled by Pearson function.

  if obj.Export2Py

    PyVis.XData = VecX;
    PyVis.YData = VecY;
    PyVis.Stats.r = r;
    PyVis.Stats.t = t;
    PyVis.Stats.pval = pval;
    PyVis.Stats.hboot = hboot;
    PyVis.Stats.CI = CI;
    PyVis.XLabel = XLabel;
    PyVis.YLabel = YLabel;
    obj.Results.Correlation(zz,kk).Pearson.PyVis = PyVis;

  end


  obj.Results.Correlation(zz,kk).Pearson.r = r;
  obj.Results.Correlation(zz,kk).Pearson.t = t;
  obj.Results.Correlation(zz,kk).Pearson.pval =  pval;
  obj.Results.Correlation(zz,kk).Pearson.hboot = hboot;
  obj.Results.Correlation(zz,kk).Pearson.CI = CI;
  end
  end

end % Correlation

function obj = runCorSpearman(obj,crObj)

  % Developers: * qmrstat.getBivarCorInputs (Static)
  %               -- calls qmrstat.getBiVarCorVec (Private)
  %               ---- calls qmrstat.cleanNan (Private)
  %             * Pearson (External/robustcorrtool)

  % getBivarCorInputs includes validation step. Validation step
  % is not specific to the object arrays with 2 objects. N>2 can
  % be also validated by qmrstat.validate (private).


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

    [r,t,pval,hboot,CI] = Spearman(VecX,VecY,XLabel,YLabel,1,sig);

  elseif strcmp(crObj(1).FigureOption,'save')

    [r,t,pval,hboot,CI,h] = Spearman(VecX,VecY,XLabel,YLabel,1,sig);
    obj.Results.Correlation(zz,kk).Spearman.figure = h;
    
    if lbIdx>1

    obj.Results.Correlation(zz,kk).Spearman.figLabel = [XLabel '_' YLabel '_' curObj(1).StatLabels(zz)];

    else
        
    obj.Results.Correlation(zz,kk).Spearman.figLabel = [XLabel '_' YLabel];    
    
    end
    
  elseif strcmp(crObj(1).FigureOption,'disable')


    [r,t,pval,hboot,CI] = Spearman(VecX,VecY,XLabel,YLabel,0,sig);

  end

  % Corvis is assigned to caller (qmrstat.Pearson) workspace by
  % the Pearson function.
  % Other fields are filled by Pearson function.

  if obj.Export2Py

    PyVis.Stats.r = r;
    PyVis.Stats.t = t;
    PyVis.Stats.pval = pval;
    PyVis.Stats.hboot = hboot;
    PyVis.Stats.CI = CI;
    PyVis.XLabel = XLabel;
    PyVis.YLabel = YLabel;
    obj.Results.Correlation(zz,kk).Spearman.PyVis = PyVis;

  end


  obj.Results.Correlation(zz,kk).Spearman.r = r;
  obj.Results.Correlation(zz,kk).Spearman.t = t;
  obj.Results.Correlation(zz,kk).Spearman.pval =  pval;
  obj.Results.Correlation(zz,kk).Spearman.hboot = hboot;
  obj.Results.Correlation(zz,kk).Spearman.CI = CI;
  end
  end
end % Correlation 

function obj = runCorSkipped(obj,crObj)

  % Developers: * qmrstat.getBivarCorInputs (Static)
  %               -- calls qmrstat.getBiVarCorVec (Private)
  %               ---- calls qmrstat.cleanNan (Private)
  %             * Pearson (External/robustcorrtool)

  % getBivarCorInputs includes validation step. Validation step
  % is not specific to the object arrays with 2 objects. N>2 can
  % be also validated by qmrstat.validate (private).

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

    [r,t,~,~,hboot,CI] = skipped_correlation(VecX,VecY,XLabel,YLabel,1,sig);

  elseif strcmp(crObj(1).FigureOption,'save')

    [r,t,~,~,hboot,CI,h] = skipped_correlation(VecX,VecY,XLabel,YLabel,1,sig);
    obj.Results.Correlation(zz,kk).Skipped.figure = h;

    if lbIdx>1

    obj.Results.Correlation(zz,kk).Skipped.figLabel = [XLabel '_' YLabel '_' curObj(1).StatLabels(zz)];

    else
        
    obj.Results.Correlation(zz,kk).Skipped.figLabel = [XLabel '_' YLabel];    
    
    end
    
  elseif strcmp(crObj(1).FigureOption,'disable')


    [r,t,~,~,hboot,CI] = skipped_correlation(VecX,VecY,XLabel,YLabel,0,sig);

  end

  % Corvis is assigned to caller (qmrstat.Pearson) workspace by
  % the Pearson function.
  % Other fields are filled by Pearson function.

  if obj.Export2Py

    PyVis.XLabel = XLabel;
    PyVis.YLabel = YLabel;
    PyVis.Stats.r = r;
    PyVis.Stats.t = t;
    PyVis.Stats.hboot = hboot;
    PyVis.Stats.CI = CI;
    obj.Results.Correlation(zz,kk).Skipped.PyVis = PyVis;

  end


  obj.Results.Correlation(zz,kk).Skipped.r = r;
  obj.Results.Correlation(zz,kk).Skipped.t = t;
  obj.Results.Correlation(zz,kk).Skipped.hboot = hboot;
  obj.Results.Correlation(zz,kk).Skipped.CI = CI;
  end
  end
end % Correlation 

function obj = runCorInspect(obj,crObj)

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
end % Correlation

function obj = runCorPrcntgBend(obj,crObj)

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


end % Correlation

% ############################ CONCORDANCE

function obj = runCorConcordance(obj,crObj)

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
  end
  
end


% ############################ RELAIBILITY TEST FAMILY 

function obj = runRelCompare(obj,rlObj)
    
  if nargin<2
      
    rlObj = obj.Object.Reliability;
    
  elseif nargin == 2
      
    obj.Object.Reliability = rlObj;  
  
  end
  
  [comb, lblN] = qmrstat.relSanityCheck(rlObj);
  
  for kk = 1:length(comb) % Loop over pair combinations 
  for zz = 1:lblN % Loop over labeled mask indexes
      
  % Combine pairs 
  curObj = [rlObj(comb(kk,1),:);rlObj(comb(kk,2),:)];
  
  if lblN >1
      
      % If mask is labeled, masking will be done by the corresponding
      % index, if index is passed as the third parameter.
      
      [PairX,PairY,XLabel,YLabel,sig] = qmrstat.getReliabilityInputs(obj,curObj,curObj(1,1).LabelIdx(zz));
  else
      % If mask is binary, then index won't be passed.
      [PairX,PairY,XLabel,YLabel,sig] = qmrstat.getReliabilityInputs(obj,curObj);
  
  end
  
 [CIP,pP,CIX,pC]=qmrstat_compcorr(PairX,PairY,XLabel,YLabel,'Both',1,sig);
  
  
  
  
  
  end
  end



end


% ############################# GENERIC METHODS

function obj = pyExportEnable(obj)

  obj.Export2Py = true;

end % Generic 

function obj = pyExportDisable(obj)

  obj.Export2Py = false;

end % Generic 

function obj = setOutputDir(obj,input)

    if exist(input,'file') ~= 7 % Folder
       
        try
        mkdir(input);
        obj.OutputDir = input;
        catch
        error([obj.ErrorHead ...
            '\n>>>>>> %s create directory:'...
            '\n>>>>>> %s'...
            obj.Tail],'Cannot',input);
        end
    else
        obj.OutputDir = input;
    end
    
end % Generic 

function obj = saveStaticFigures(obj)
   % To save figures if methods are run after enabling 'save' section. 
   % If labeled mask to be used, both MaskLabel and MaskIdx should be available
   
    if isempty(obj.OutputDir)
        mkdir([pwd filesep 'qmrstat_Figures']);
        obj = obj.setOutputDir([pwd filesep 'qmrstat_Figures']);
    end
    
    if ~isempty(fieldnames(obj.Results))
        
        namesFamily = fieldnames(obj.Results);
        for ii = 1:length(namesFamily)
            
           familyStr = obj.Results.(namesFamily{ii}); % Pearson %Skipped 
           sz = size(familyStr);
           tests = fieldnames(familyStr);
           
           for k =1:sz(1)
               for l=1:sz(2)
                   for m=1:length(tests)
                       
                   crFig = familyStr(k,l).(tests{m}).figure;
                   lbl = familyStr(k,l).(tests{m}).figLabel;
                   
                   if ~isempty(crFig)
                       saveas(crFig, [obj.OutputDir filesep tests{m} '_' cell2mat(lbl) '.png']);    
                   end
              
                   end
               end
           end
        end
        
    else
        error( [obj.ErrorHead ...
    '\n>>>>>> qmrstat.%s field is empty'...
    '\n>>>>>> No analysis has been performed.'...
    '\n>>>>>> setFigureOption must be set to ''save'' for the qmrstat_statobj'...
    obj.Tail],'Results'); 
    end
    
    
end % Generic 

end

% ===============================================================

methods(Access=private)

function obj = validate(obj,curObj,name,lblIdx)

  % This validation is for statistical methods those require spatial
  % correspondance.


  if isempty(obj.Object.(name))

    % In case user removes field by mistake

    error( [obj.ErrorHead ...
    '\n>>>>>> Object.%s is empty'...
    obj.Tail],name);

  else

    boolMap = zeros(length(curObj),1);
    boolMask = boolMap;
    dimMis = [];
    for ii = 1:length(curObj)

      curObj(ii) = curObj(ii).evalCompliance();
      boolMap(ii) = curObj(ii).Compliance.noMapFlag;
      boolMask(ii) = curObj(ii).Compliance.noMaskFlag;
      if ~isempty(curObj(ii).StatMask)
        dimMis = [dimMis curObj(ii).Compliance.szMismatchFlag];
      end
    end

  end

  % This check must be passed for all stats objects. All
  % of the objects of an object array must contain a
  % mask.

  % Should all Maps match in size?
  % - Yes.
  % But, for example I have a volumetric VFA T1 map, and
  % a single slice MWF. I want to see how they correlate.
  % Then this dimension mismatch won't allow me to do it.
  % - MWF must be a subset of that VFA-T1 volume. Extract
  % the corresponding VFA-T1 subset both for Map and
  % StatMask. The images should have been resolution
  % matched already.

  if any(boolMap)

    for ii = 1:length(find(boolMap==1))

      warning([obj.WarningHead ...
      '\n>>>>>> Object.%s(%d).Map is empty.'...
      obj.Tail],name,ii);

    end

    error( [obj.ErrorHead...
    '\n>>>>>> Detected empty objects in qmrstat.Object.%s.Map object array.'...
    obj.Tail],name);

  end

  % If none of the objects in an object array contains a
  % StatMask, operation must be terminated.
  % This statement may need modification regarding the
  % curation of ProbMask.

  if all(boolMask)

    error( [obj.ErrorHead...
    '\n>>>>>> Object.%s(N).StatMask property must be loaded at least for one of the pairs'...
    obj.Tail],name);

  end

  
  % If there is any dimension mismatch between the map
  % and the loaded mask belonging to an object of an object
  % array, operation must be terminated.

  if any(dimMis)

    error( [obj.ErrorHead...
    '\n>>>>>> Dimension mismatch detected between Object.%s(%d).Map and Object.%s(%d).StatMask'...
    obj.Tail],name,find(dimMis==1),name,find(dimMis==1));

  end

  
  % More than one masks are loaded, but one they are not
  % identical. Assume that both masks have equal numbers
  % of foreground voxels located in diferent positions.
  % The comparison would be invalid (at least for cors).

  if sum(boolMask==0)>1
    idx = boolMask == 0;
    for ii = 2:length(idx)

      curBool = isequal(obj.Object.(name)(idx(1)).StatMask,obj.Object.(name)(idx(ii)).StatMask);

      if ~curBool

        error( [obj.ErrorHead...
        '\n>>>>>> Object.%s(%d).StatMask is not identical with the Object.%s(1).StatMask'...
        obj.Tail],name,ii,name);

      end


    end

  end


  % If survived all these, then
  obj.([name 'Valid']) = 1;

  inflag = 0;
  iter  = 1;

  while inflag ==0

    if ~isempty(obj.Object.(name)(iter).StatMask)

      if nargin == 4 % Means labeled mask
         
          msk = obj.Object.(name)(iter).StatMask;
          msk(msk~=lblIdx) = 0;
          msk = logical(msk);
          obj.([name 'JointMask']) = msk;
      
      else % Means logical mask
          
          obj.([name 'JointMask']) = obj.Object.(name)(iter).StatMask;
      
      end
      
      inflag = 1;

    end

    if iter == length(obj.Object.(name))
      % If this was the case, validation would have errored
      % above, just precaution.

      inflag =1;
      obj.([name 'JointMask']) = [];

    end

    iter = iter+1;

  end




end % Generic

function [obj,VecX,VecY] = getBivarCorVec(obj,crObj,name,lblIdx)

  % The statement below errors if name passes is not a property of
  % qmrstat class. For example, name = 'Correlation' is for the
  % objects of qmrstat_correlation class.

  if nargin ==4
      obj = validate(obj,crObj,name,lblIdx);
  else
      obj = validate(obj,crObj,name);
  end

  if obj.([name 'Valid'])


    % Mapnames can be multidim. This function is exclusive for bivariate
    % operations. 

    mp1 = crObj(1).getActiveMap();
    mp2 = crObj(2).getActiveMap();

    % Learn mask type here.

    VecX = mp1(obj.([name 'JointMask']));
    VecY = mp2(obj.([name 'JointMask']));
    

    % In correlation  class, there should be no NaN's under masked area
    % if exists, vals should be removed from both vectors.

    [VecX,VecY] = qmrstat.cleanNan(VecX,VecY);

  end

end % Correlation

function [obj,PairX,PairY] = getRelPairs(obj,rlObj,name,lblIdx)
% 2XN qmrstat_relaibility object
  
  if nargin ==4
      obj = validate(obj,rlObj,name,lblIdx);
  else
      obj = validate(obj,rlObj,name);
  end

  if obj.([name 'Valid'])


    PairX1 = rlObj(1,1).getActiveMap();
    PairX2 = rlObj(1,2).getActiveMap();
    
    PairY1 = rlObj(2,1).getActiveMap();
    PairY2 = rlObj(2,2).getActiveMap();


    VecX1 = PairX1(obj.([name 'JointMask']));
    VecX2 = PairX2(obj.([name 'JointMask']));
    
    VecY1 = PairY1(obj.([name 'JointMask']));
    VecY2 = PairY2(obj.([name 'JointMask']));
    

    % In correlation  class, there should be no NaN's under masked area
    % if exists, vals should be removed from both vectors.
    
    [PairX,PairY] = qmrstat.cleanNanComp(VecX1, VecX2, VecY1, VecY2);

  end
  
end % Reliability





end

% ===============================================================

methods(Static, Hidden)


function [Vec1Out,Vec2Out] = cleanNan(Vec1, Vec2)

  joins = or(isnan(Vec1),isnan(Vec2));
  Vec1Out = Vec1(not(joins));
  Vec2Out = Vec2(not(joins));


end % Generic 
% cleanNan functions can be written in a more smart way later. 
function [Pair1Out,Pair2Out] = cleanNanComp(Vec1, Vec2, Vec3, Vec4)

  joins1 = or(isnan(Vec1),isnan(Vec2));
  joins2 = or(isnan(Vec3),isnan(Vec4));
  joins = or(joins1,joins2);
  
  Pair1Out(:,1) = Vec1(not(joins));
  Pair1Out(:,2) = Vec2(not(joins));
  
  Pair2Out(:,1) = Vec3(not(joins));
  Pair2Out(:,2) = Vec4(not(joins));


end % Generic 

function [VecX,VecY,XLabel,YLabel,sig] = getBivarCorInputs(obj,crObj,lblIdx)

  if nargin == 3  
  [obj,VecX,VecY] = obj.getBivarCorVec(crObj,'Correlation',lblIdx);
  else
  [obj,VecX,VecY] = obj.getBivarCorVec(crObj,'Correlation');
  end
  XLabel = crObj(1).MapNames(crObj(1).ActiveMapIdx);
  YLabel = crObj(2).MapNames(crObj(2).ActiveMapIdx);

  % Call Pearson function from External/robustcorrtool
  % ADD: Show output fig vs save output fig.

  if ~isequal(crObj(1).SignificanceLevel,crObj(2).SignificanceLevel)

    error( [obj.ErrorHead...
    '\n>>>>>> SignificanceLevel property of Object.%s must be the same for all objects in the array'...
    '\n>>>>>> Avoid assigning individual objects for this property.'...
    '\n>>>>>> Correct use: Correlation.setSignificanceLevel(0.01).'...
    '\n>>>>>> Wrong use  : Correlation(1).setSignificanceLevel(0.01).'...
    obj.Tail],'Correlation');

  end

  if ~isequal(crObj(1).FigureOption,crObj(2).FigureOption)

    error( [obj.ErrorHead...
    '\n>>>>>> FigureOption property of Object.%s must be the same for all objects in the array'...
    '\n>>>>>> Avoid assigning individual objects for this property.'...
    '\n>>>>>> Correct use: Correlation.setFigureOption(''save'').'...
    '\n>>>>>> Wrong use  : Correlation(1).setFigureOption(''save'').'...
    obj.Tail],'Correlation');
  end

  if crObj(1).SignificanceLevel ~= 5/100

    sig  = crObj(1).SignificanceLevel;
  else
    sig = 5/100;
  end





end % Correlation

function [PairX,PairY,XLabel,YLabel,sig] = getReliabilityInputs(obj,rlObj,lblIdx) % Reliability 
 
  if nargin == 3  
  [obj,PairX,PairY] = obj.getRelPairs(rlObj,'Reliability',lblIdx);
  else
  [obj,PairX,PairY] = obj.getRelPairs(rlObj,'Reliability');
  end
  
  XLabel = rlObj(1,1).MapNames(rlObj(1,1).ActiveMapIdx);
  XLabel2 = rlObj(1,2).MapNames(rlObj(1,2).ActiveMapIdx);
  
  YLabel = rlObj(2,1).MapNames(rlObj(2,1).ActiveMapIdx);
  YLabel2 = rlObj(2,2).MapNames(rlObj(2,2).ActiveMapIdx);
  
 % if ~isequal(XLabel,XLabel2) || ~isequal(YLabel,YLabel2)


  %  error( [obj.ErrorHead...
  %  '\n>>>>>> MapNames must be matched within pairs'...
  %  '\n>>>>>> Reliability(N,1).ActiveMapIdx == Reliability(N,2).ActiveMapIdx'...
  %  obj.Tail],'Reliability');

 % end
  
  if ~isequal(rlObj(:,1).SignificanceLevel,rlObj(:,2).SignificanceLevel)


    error( [obj.ErrorHead...
    '\n>>>>>> SignificanceLevel property of Object.%s must be the same for all objects in the array'...
    '\n>>>>>> Avoid assigning individual objects for this property.'...
    '\n>>>>>> Correct use: Reliability.setSignificanceLevel(0.01).'...
    '\n>>>>>> Wrong use  : Reliability(1,1).setSignificanceLevel(0.01).'...
    obj.Tail],'Reliability');

  end

  if ~isequal(rlObj(:,1).FigureOption,rlObj(:,2).FigureOption) ...

 
    error( [obj.ErrorHead...
    '\n>>>>>> FigureOption property of Object.%s must be the same for all objects in the array'...
    '\n>>>>>> Avoid assigning individual objects for this property.'...
    '\n>>>>>> Correct use: Reliability.setFigureOption(''save'').'...
    '\n>>>>>> Wrong use  : Reliability(1,1).setFigureOption(''save'').'...
    obj.Tail],'Reliability');
  end
  
  
  
  if rlObj(1).SignificanceLevel ~= 5/100
    sig  = rlObj(1).SignificanceLevel;
  else
    sig = 5/100;
  end
  
  end

function [comb, lblN] = corSanityCheck(crObj)
  % Important function, returns iteration indexes. 
  % Consider renaming 
  
      sz = size(crObj);
  
      
  if sz(1) > 1
    error( [crObj.ErrorHead ...
        '\n>>>>>> Object.%s for this method cannot have multiple object arrays of qmrstat_correlation class.'...
        '\n>>>>>> Correct use: Object.Correlation = qmrstat_correlation(1,4)'...
        '\n>>>>>> Wrong use  : Object.Correlation = qmrstat_correlation(2,4)'...
        '\n>>>>>> Where Object.Correlation is passed to the qmrstat.runCorPearson method.'...
        crObj.Tail],'Correlation');
  end

  if sz(2) > 2 
     
      comb = nchoosek(1:sz(2),2);
      obj.MultipleCorrelation = true;
      crObj = crObj.setSignificanceLevel(crObj(1).SignificanceLevel/length(comb));
      disp(['Significance level is adjusted to ' num2str(crObj(1).SignificanceLevel) ' for ' num2str(length(comb)) ' correlations.']);     
      
  else
      
      comb = nchoosek(1:2,2);
 
  end
  
  if length(crObj(1).StatLabels)>1
     
      lblN = length(crObj(1).StatLabels);
      
  else
      
      lblN = 1;
 
  end
  
    
end % Correlation 

function [comb, lblN] = relSanityCheck(rlObj)   
 
  sz = size(rlObj);
  
  if sz(2) < 2
    error( [rlObj.ErrorHead ...
        '\n>>>>>> Object.%s for this method must at least be: qmrstat_correlation(2,2) '...
        '\n>>>>>> qmrstat_correlation(N,2) is allowed, where N dependent pairs will be compared in (N choose 2) combinations)'...
        '\n>>>>>> Correct use: Object.Reliability = qmrstat_correlation(2,2)'...
        '\n>>>>>> Wrong use  : Object.Reliability = qmrstat_correlation(2,1)'...
        rlObj.Tail],'Reliability');
  end

  if sz(1) > 2 
     
      comb = nchoosek(1:sz(1),2);
      obj.MultipleReliability = true;
      rlObj = crObj.setSignificanceLevel(rlObj(1,1).SignificanceLevel/length(comb));
      disp(['Significance level is adjusted to ' num2str(rlObj(1,1).SignificanceLevel) ' for ' num2str(length(comb)) ' correlations.']);     
      
  else
      
      comb = nchoosek(1:2,2);
 
  end
  
  if length(rlObj(1,1).StatLabels)>1
     
      lblN = length(rlObj(1,1).StatLabels);
      
  else
      
      lblN = 1;
 
  end

end


end

% ===============================================================

end % End of class definition for qmrstat
