classdef qmrstat

    
    
% ===============================================================        
    properties
        
        Object
        
    end
    
% ===============================================================

    properties (Access = private, Hidden)
        
        CorrelationValid
        CorrelationJointMask
        TestRetesValid
        Export2Py = false;
        
        WarningHead = '-------------------------------- qMRLab Warning';
        ErrorHead   = '----------------------------------------- qMRLab Error';
        Tail = '\n-------------------------------------------------------|';
        
        
        
        
    end

% ===============================================================    
    
    properties (SetAccess = private, GetAccess=public)
        
        Results = struct();
        
        
    end
       
% ===============================================================    
    
    methods
        
        
        function obj = qmrstat()
            
            obj.Object.TestRetest =  test_retest({'Session-1','Session-2'});
            obj.Object.Correlation = qmrstat_correlation;
            %obj.Object.Concordance = concordance;
            
            
        end % Constructor  ------------------------ end (Public)
        
        
        
        function obj = runPearsonCor(obj,crObj)
            %Explain for user here. 
            
            % Developers: * qmrstat.getBivarCorInputs (Static)
            %               -- calls qmrstat.getBiVarCorVec (Private)
            %               ---- calls qmrstat.cleanNan (Private)
            %             * Pearson (External/robustcorrtool)
            
            % getBivarCorInputs includes validation step. Validation step
            % is not specific to the object arrays with 2 objects. N>2 can
            % be also validated by qmrstat.validate (private).
            
            [VecX,VecY,XLabel,YLabel,sig] = qmrstat.getBivarCorInputs(obj,crObj);
            
            if strcmp(crObj(1).FigureOption,'osd')
                
                [r,t,pval,hboot,CI] = Pearson(VecX,VecY,XLabel,YLabel,1,sig);
                
            elseif strcmp(crObj(1).FigureOption,'save')
                
                [r,t,pval,hboot,CI,h] = Pearson(VecX,VecY,XLabel,YLabel,1,sig);
                obj.Results.Correlation.Pearson.figure = h;
                
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
                obj.Results.Correlation.Pearson.PyVis = PyVis;
                
            end
          
            
            obj.Results.Correlation.Pearson.r = r;
            obj.Results.Correlation.Pearson.t = t;
            obj.Results.Correlation.Pearson.pval =  pval;
            obj.Results.Correlation.Pearson.hboot = hboot;
            obj.Results.Correlation.Pearson.CI = CI;
            
            
        end % runPearsonCor  ------------------------ end (Public)
        
        
        function obj = runSpearmanCor(obj,crObj)
            
            % Developers: * qmrstat.getBivarCorInputs (Static)
            %               -- calls qmrstat.getBiVarCorVec (Private)
            %               ---- calls qmrstat.cleanNan (Private)
            %             * Pearson (External/robustcorrtool)
            
            % getBivarCorInputs includes validation step. Validation step
            % is not specific to the object arrays with 2 objects. N>2 can
            % be also validated by qmrstat.validate (private).
            
            [VecX,VecY,XLabel,YLabel,sig] = qmrstat.getBivarCorInputs(obj,crObj);
            
            if strcmp(crObj(1).FigureOption,'osd')
                
                [r,t,pval,hboot,CI] = Spearman(VecX,VecY,XLabel,YLabel,1,sig);
                
            elseif strcmp(crObj(1).FigureOption,'save')
                
                [r,t,pval,hboot,CI,h] = Spearman(VecX,VecY,XLabel,YLabel,1,sig);
                obj.Results.Correlation.Spearman.figure = h;
                
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
                obj.Results.Correlation.Spearman.PyVis = PyVis;
                
            end
          
            
            obj.Results.Correlation.Spearman.r = r;
            obj.Results.Correlation.Spearman.t = t;
            obj.Results.Correlation.Spearman.pval =  pval;
            obj.Results.Correlation.Spearman.hboot = hboot;
            obj.Results.Correlation.Spearman.CI = CI;
        
        end % runSpearmanCor  ------------------------ end (Public) 
        
        
        function obj = runSkippedCor(obj,crObj)
        
             % Developers: * qmrstat.getBivarCorInputs (Static)
            %               -- calls qmrstat.getBiVarCorVec (Private)
            %               ---- calls qmrstat.cleanNan (Private)
            %             * Pearson (External/robustcorrtool)
            
            % getBivarCorInputs includes validation step. Validation step
            % is not specific to the object arrays with 2 objects. N>2 can
            % be also validated by qmrstat.validate (private).
            
            [VecX,VecY,XLabel,YLabel,sig] = qmrstat.getBivarCorInputs(obj,crObj);
            
            if strcmp(crObj(1).FigureOption,'osd')
                
                [r,t,~,~,hboot,CI] = skipped_correlation(VecX,VecY,XLabel,YLabel,1,sig);
                
            elseif strcmp(crObj(1).FigureOption,'save')
                
                [r,t,~,~,hboot,CI,h] = skipped_correlation(VecX,VecY,XLabel,YLabel,1,sig);
                obj.Results.Correlation.Skipped.figure = h;
                
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
                obj.Results.Correlation.Skipped.PyVis = PyVis;
                
            end
          
            
            obj.Results.Correlation.Skipped.r = r;
            obj.Results.Correlation.Skipped.t = t;
            obj.Results.Correlation.Skipped.hboot = hboot;
            obj.Results.Correlation.Skipped.CI = CI;
        
        end % runSpearmanCor  ------------------------ end (Public)
        
        
        function obj = runInspectCor(obj,crobj)
           
            % WRITE THEM IN A TABLE AND SAVE FIGURES
            h1 = corr_normplot(X,Y);
            joint_density(X,Y,1)
            % 2 - performs the Henze- Zirkler test for normality
            [results.normality.test_value,results.normality.p_value] = HZmvntest(X,Y,level);
            [results.conditional.values,results.conditional.variances]=conditional(X,Y);
            [h,results.heteroscedasticity.CI] = variance_homogeneity(X,Y,1);
            results.outliers = detect_outliers(X,Y);

            
        end
        
        function obj = runCompareCor(obj,corob1,corob2)
            
           % Compare correlations 
            
            
        end
        
        function obj = pyExportEnable(obj)
           
           obj.Export2Py = true; 
            
        end % pyExportEnable  ------------------------ end (Public)
        
        function obj = pyExportDisable(obj)
           
           obj.Export2Py = false; 
            
        end % pyExportEnable  ------------------------ end (Public)
        
    end
    
% ===============================================================        
    
    methods(Access=private)
        
        
        function obj = validate(obj,name)
            
            % This validation is for statistical methods those require spatial
            % correspondance.
            
            
            if isempty(obj.Object.(name))
                
                % In case user removes field by mistake
                
                error( [obj.ErrorHead ...
                    '\n>>>>>> Object.%s is empty'...
                    obj.Tail],name);
                
            else
                
                boolMap = zeros(length(obj.Object.(name)),1);
                boolMask = boolMap;
                dimMis = [];
                for ii = 1:length(obj.Object.(name))
                    
                    obj.Object.(name)(ii) = obj.Object.(name)(ii).evalCompliance();
                    boolMap(ii) = obj.Object.(name)(ii).Compliance.noMapFlag;
                    boolMask(ii) = obj.Object.(name)(ii).Compliance.noMaskFlag;
                    if ~isempty(obj.Object.(name)(ii).StatMask)
                        dimMis = [dimMis obj.Object.(name)(ii).Compliance.szMismatchFlag];
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
                    '\n>>>>>> Object.%s(N).StatMask property must be loaded at least for one of the objects in the object array'...
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
                    
                    obj.([name 'JointMask']) = obj.Object.(name)(iter).StatMask;
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
            
            
        end % validate  ------------------------ end (Private)
        
        
        
        
        function [VecX,VecY] = getBivarCorVec(obj,crObj,name)
            
            % The statement below errors if name passes is not a property of
            % qmrstat class. For example, name = 'Correlation' is for the
            % objects of qmrstat_correlation class.
            
            obj.Object.(name) = crObj;
            
            obj = validate(obj,name);
            
            if obj.([name 'Valid'])
                
                
                % Mapnames can be multidim.
                
                mp1 = crObj(1).getActiveMap();
                mp2 = crObj(2).getActiveMap();
                
                % Learn mask type here. 
                
                VecX = mp1(obj.([name 'JointMask']));
                VecY = mp2(obj.([name 'JointMask']));
                
                % In correlation  class, there should be no NaN's under masked area
                % if exists, vals should be removed from both vectors.
                
                [VecX,VecY] = qmrstat.cleanNan(VecX,VecY);
                
            end
            
        end % getBivarCorVec ------------------------ end (Private)
        
        
        
        
        
        
    end
    
% ===============================================================        
     
    methods(Static, Hidden)
        
        
        function [Vec1Out,Vec2Out] = cleanNan(Vec1, Vec2)
            
            joins = or(isnan(Vec1),isnan(Vec2));
            Vec1Out = Vec1(not(joins));
            Vec2Out = Vec2(not(joins));
            
            
        end
        
                        
        function [VecX,VecY,XLabel,YLabel,sig] = getBivarCorInputs(obj,crObj)
        
            
            [VecX,VecY] = obj.getBivarCorVec(crObj,'Correlation');
            
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
            
            
            
            
            
        end
        
        
        
    end
    
% ===============================================================   
    
end % End of class definition for qmrstat