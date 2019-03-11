function Correlation = corSkipped(obj,crObj)

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

  % This is a whole other story with corSkipped. 
  % Try to pack multiple observations into columns, and then call the original function 
  % Then wrap outputs. 

  [comb, lbIdx, sig] = qmrstat.corInit(crObj);
  crObj = crObj.setSignificanceLevel(sig);

  szcomb = size(comb);
  Correlation = repmat(struct(), [lbIdx szcomb(1)]);
  
  % !!!!!! Changed nested loop order. Skipped correlation has a diferent
  % design for multiple comparison correction. 
  % Per label, pair combinations will be accumulated and passed to the 
  % original (mostly) skipped correlation script. 
  % It has multiple assumptions depending on  the number of comparisons. 
  
  
  for kk = 1:lbIdx % Loop over labeled mask indexes (if available)
    
    for zz = 1:szcomb(1) % Loop over correlation matrix combinations
        

      % Combine pairs
      curObj = [crObj(1,comb(zz,1)),crObj(1,comb(zz,2))];

      if lbIdx >1

        % If mask is labeled, masking will be done by the corresponding
        % index, if index is passed as the third parameter.
        [VecX,VecY,XLabel,YLabel,sig] = qmrstat.getBivarCorInputs(obj,curObj,curObj(1).LabelIdx(kk));

        if zz == 1
          % Initialize new accumulators when the combination loop restarts per label. 
          
          accumulateX = zeros(length(VecX),szcomb(1));
          accumulateY  = zeros(length(VecY),szcomb(1));
          accumulateXLabel = cell(szcomb(1));
          accumulateYLabel = cell(szcomb(1));
       
        end

      else
        % If mask is binary, then index won't be passed.
        [VecX,VecY,XLabel,YLabel,sig] = qmrstat.getBivarCorInputs(obj,curObj);

        if zz == 1 
          % Initialize new accumulators when the combination loop restarts per label. 
          accumulateX = zeros(length(VecX),szcomb(1));
          accumulateY  = zeros(length(VecY),szcomb(1));
          accumulateXLabel = cell(szcomb(1));
          accumulateYLabel = cell(szcomb(1));
        end

      end

      accumulateX(:,zz) = VecX;
      accumulateY(:,zz) = VecY;
      accumulateXLabel{zz} = XLabel;
      accumulateYLabel{zz} = XLabel;

    end % Per label. 

    % Do per label operations. 

    % IMPORTANT 
    %
    % skipped_correlation @qmrlab is reverted back to the Cyril's original script. 
    % Change the convention in loading svd objects and collecting figures depending on the mode
    % of the iterations over label. Inner loop is now NUMBER OF PAIRS. 

    if strcmp(crObj(1).FigureOption,'osd')

      [r,t,~,~,hboot,CI] = skipped_correlation(VecX,VecY,XLabel,YLabel,1,sig);

    elseif strcmp(crObj(1).FigureOption,'save')

      [r,t,~,~,hboot,CI,Correlation(zz,kk).figure] = skipped_correlation(VecX,VecY,XLabel,YLabel,1,sig);

      if lbIdx>1

      Correlation(zz,kk).figLabel = [XLabel '_' YLabel '_' num2str(curObj(1).StatLabels{zz})];

      else

      Correlation(zz,kk).figLabel = [XLabel '_' YLabel];

      end

    elseif strcmp(crObj(1).FigureOption,'disable')


      [r,t,~,~,hboot,CI] = skipped_correlation(VecX,VecY,XLabel,YLabel,0,sig);

    end

    % Developer:
    % svds is assigned to caller (qmrstat.Concordance) workspace by
    % the Concordance function.
    % Other fields are filled out here below.

    if obj.Export2Py

      svds.Tag.Class = 'Correlation::Skipped';
      svds.Required.xData = VecX';
      svds.Required.yData = VecY';
      svds.Required.rSpearman = r.Spearman;
      svds.Required.rPearson = r.Pearson;
      svds.Required.xLabel = XLabel';
      svds.Required.yLabel = YLabel';

      svds.Optional.CISpearman = CI.Spearman';
      svds.Optional.CIPearson =  CI.pearson';
      svds.Optional.CILevel = 1 - sig;
      svds.Optional.hSpearman = hboot.Spearman;
      svds.Optional.hPearson = hboot.Pearson;
      Correlation(zz,kk).SVDS = svds;
      
    end


    Correlation(zz,kk).rSpearman = r.Spearman;
    Correlation(zz,kk).rPearson = r.Pearson;
    Correlation(zz,kk).t = t;
    Correlation(zz,kk).hboot = hboot;
    Correlation(zz,kk).CI = CI;

  end

end % Correlation
