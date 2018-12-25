classdef qmrstat
% qmrstat (main) class
% Objects constructed from this class can:
%
%      i)   Orchestrate objects instantiated from qmrstat_sub classes
%     ii)   Validate objects for statistical tests
%    iii)   Perform statistical tests
%     iv)   Store and export results


properties

Object
Export2Py = false;
OutputDir

end

% ////////////////////////////////////////////////////////////////

properties (Access = private)

CorrelationValid
CorrelationJointMask

ReliabilityValid
ReliabilityJointMask
MultipleReliability

WarningHead = '-------------------------------- qMRLab Warning';
ErrorHead   = '----------------------------------------- qMRLab Error';
Tail = '\n-------------------------------------------------------|';

end

% ////////////////////////////////////////////////////////////////

properties (SetAccess = public, GetAccess=public)
% Results property of the qmrstat cannot be modified outside.
% However, can be accessed.

Results = struct();

end

% ////////////////////////////////////////////////////////////////


methods

    function obj = mountCorOut(obj,inp,name)
        % Matlab and Octave togethernes...
        sz = size(inp);

        for ii = 1:sz(1)
            for jj = 1:sz(2)

            obj.Results.Correlation(ii,jj).(name) = inp(ii,jj);

            end
        end
    end


function obj = qmrstat()

  obj.Object.Correlation = qmrstat_correlation;
  obj.Object.Reliability = qmrstat_reliability;


end % Constructor  ------------------------ end (Public)


% ############################ ROBUST CORRELATION FAMILY

function obj = corWrapper(obj,crObj,method)

     if not(isequal(crObj.MapLoadFormat,crObj.MaskLoadFormat))

     warning( [obj.WarningHead...
    '\n>>>>>> %s are not loaded from the same type of data.'...
    '\n>>>>>> This may be causing map/mask misalignment due to orientation'...
    '\n>>>>>> differences between MATLAB and NIFTI files.'...
    '\n>>>>>> Ignore this warning if you are ensured that maps/masks are aligned after loading.'...
    obj.Tail],'Maps and StatMask ');

     end



     switch method

         case 'Pearson'

             inp = corPearson(obj,crObj);
             obj = mountCorOut(obj,inp,'Pearson');

         case 'Skipped'

             [obj.Results.Correlation(:)] = corSkipped(obj,crObj);

         case 'Inspect'

             [obj.Results.Correlation(:)] = corInspect(obj,crObj);

         case 'Bend'

             [obj.Results.Correlation(:)] = corPrcntgBend(obj,crObj);

         case 'Concordance'

             [obj.Results.Correlation(:)] = corConcordance(obj,crObj);

         case 'Spearman'

             inp = corSpearman(obj,crObj);
             obj = mountCorOut(obj,inp,'Spearman');
     end


end



function obj = runCorPearson(obj,crObj)

  obj = corWrapper(obj,crObj,'Pearson');

end

function obj = runCorSpearman(obj,crObj)

  obj = corWrapper(obj,crObj,'Spearman');

end


function obj = runCorSkipped(obj,crObj)

  obj = corWrapper(obj,crObj,'Skipped');

end

function obj = runCorInspect(obj,crObj)

  obj = corWrapper(obj,crObj,'Inspect');

end % Correlation

function obj = runCorPrcntgBend(obj,crObj)

  obj = corWrapper(obj,crObj,'Bend');

end % Correlation

% ############################ CONCORDANCE

function obj = runCorConcordance(obj,crObj)

  obj = corWrapper(obj,crObj,'Concordance');

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

function obj = enableSVDSExport(obj)

  obj.Export2Py = true;

end % Generic

function obj = disableSVDSExport(obj)

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

         disp(['Saving static figures to: ' obj.OutputDir]);
         try
             N = qmrstat.saveStaticFiguresSub(obj);
         catch
             error([obj.ErrorHead ...
              '\n>>>>>> %s save static figures.'...
              obj.Tail],'Cannot');
         end
         disp([num2str(N) ' static figures have been saved.'])



end

function saveSVDS(obj)


if isempty(obj.Results) || not(obj.Export2Py)

    error([obj.ErrorHead ...
      '\n>>>>>> %s due to at least one of the following:'...
      '\n>>>>>> i)  A test has not been run e.g. qmrstat.runPearsonCor(qmrstat_correlation)'...
      '\n>>>>>> ii) Export SVDS feature has not been enabled. Please see qmrstat.enableSVDSExport'...
      obj.Tail],'Cannot export SVDS');

end

if isempty(obj.OutputDir)
    warning('OutputDir was not set. Creating an output folder named qmrstat_Figures.')
    mkdir([pwd filesep 'qmrstat_Figures']);
    obj = obj.setOutputDir([pwd filesep 'qmrstat_Figures']);
end


res = obj.Results;

fnames = fieldnames(res);
lnfnames = length(fnames);

for ii = 1:lnfnames

    curStr = res.(fnames{ii});

    if strcmp(fnames{ii},'Correlation')

        corNames = fieldnames(curStr);
        szStr = size(curStr);
        curStr = reshape(curStr,[szStr(1)*szStr(2) 1]);

        for jj = 1:length(corNames)

            subStr = [curStr(:).(corNames{jj})];
            curSVDS = [subStr(:).SVDS];
            curSVDS = orderfields(curSVDS,{'Tag','Required','Optional'});
            disp(['Saving ' corNames{jj} '.json to the output directory.']);
            savejson('qmrlab_stat',curSVDS,[obj.OutputDir filesep corNames{jj} '.json']);

        end

    end

end

end % saveSVDS



end

% ////////////////////////////////////////////////////////////////

methods(Access = private)

function obj = validate(obj,curObj,name,lblIdx)


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
  %
  % - Yes.
  %
  % But, for example I have a volumetric VFA T1 map, and
  % a single slice MWF. I want to see how they correlate.
  % Then this dimension mismatch won't allow me to do it...
  %
  % - MWF must be a subset of that VFA-T1 volume. Extract
  % the corresponding VFA-T1 subset both for Map and
  % StatMask. The images should have been resolution
  % matched anyways.

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


  % More than one masks are loaded, but they are not
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
    % If there is a NaN under the masked area, Matlab goes quantum. One
    % voxel attains multiple (symmetrical) appereances. Even one or two
    % values can have detrimental effects on non-robust measures of linear
    % correlations, such as Pearson.
    % Therefore, if exists, NaN vals should be removed.

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

    [PairX,PairY] = qmrstat.cleanNanComp(VecX1, VecX2, VecY1, VecY2);

  end

end % Reliability


end % End of provate methods

% ////////////////////////////////////////////////////////////////

methods(Static, Hidden)

function N = saveStaticFiguresSub(obj)
  % To save figures if methods are run after enabling 'save' section.
  % If labeled mask to be used, both MaskLabel and MaskIdx should be available

  if isempty(obj.OutputDir)
    warning('OutputDir was not set. Creating an output folder named qmrstat_Figures.')
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
              close(crFig);
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

  N = sz(1)*sz(2)*length(tests);

end % Generic
% ---------------------------------------------------------------------
function [Vec1Out,Vec2Out] = cleanNan(Vec1, Vec2)
  % Remove NaN entries from all, if present in any of them.
  % I mean corresponding pairs.

  joins = or(isnan(Vec1),isnan(Vec2));
  Vec1Out = Vec1(not(joins));
  Vec2Out = Vec2(not(joins));


end % Generic bivariate

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

function [comb, lblN, sig] = corInit(crObj)
  % Important function for correlation tests.
  % Returns iteration indexes for correlation pairs where N > 2 (or 2).
  % Adjusts significance level using bonferonni correction.
  % Returns number of regions by controlling StatsLabels.

  if length(crObj(1).StatLabels)>1

    lblN = length(crObj(1).StatLabels);

  else

    lblN = 1;

  end

  sz = size(crObj);

  if sz(2) > 2 && lblN == 1

    comb = nchoosek(1:sz(2),2);
    szc = size(comb);
    sig = crObj(1).SignificanceLevel/szc(1);
    disp(['Significance level is adjusted to ' num2str(sig) ' for ' num2str(szc(1)) ' correlation pairs.']);

  elseif sz(2) == 2 && lblN > 1

    comb = nchoosek(1:2,2);
    sig = crObj(1).SignificanceLevel/lblN;
    disp(['Significance level is adjusted to ' num2str(sig) ' for ' num2str(lblN) ' regions.']);


  elseif sz(2) > 2 && lblN > 1

  comb = nchoosek(1:sz(2),2);
  szc = size(comb);
  sig = crObj(1).SignificanceLevel/lblN/szc(1);
  disp(['Significance level is adjusted to ' num2str(sig) ' for ' num2str(lblN) ' regions and ' num2str(szc(1)) ' correlation pairs.']);

  end

  if sz(1) > 1
    error( [crObj.ErrorHead ...
    '\n>>>>>> Object.%s for this method cannot have multiple object arrays of qmrstat_correlation class.'...
    '\n>>>>>> Correct use: Object.Correlation = qmrstat_correlation(1,4)'...
    '\n>>>>>> Wrong use  : Object.Correlation = qmrstat_correlation(2,4)'...
    '\n>>>>>> Where Object.Correlation is passed to the qmrstat.runCorPearson method.'...
    crObj.Tail],'Correlation');
  end


end

% ---------------------------------------------------- Relaibility -----

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

function [Pair1Out,Pair2Out] = cleanNanComp(Vec1, Vec2, Vec3, Vec4)
  % Remove NaN entries from all 4, if present in any of them.

  joins1 = or(isnan(Vec1),isnan(Vec2));
  joins2 = or(isnan(Vec3),isnan(Vec4));
  joins = or(joins1,joins2);

  Pair1Out(:,1) = Vec1(not(joins));
  Pair1Out(:,2) = Vec2(not(joins));

  Pair2Out(:,1) = Vec3(not(joins));
  Pair2Out(:,2) = Vec4(not(joins));


end % Generic

end % End of static methods

% ////////////////////////////////////////////////////////////////

% ------------------------------------------------------------ END --
end
