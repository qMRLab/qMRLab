classdef qmrstat
    
    
    properties
        
        Object      
        
    end
    
    properties (Access = private, Hidden)
        
        CorrelationValid
        CorrelationJointMask
        TestRetesValid
        
        WarningHead = '-------------------------------- qMRLab Warning';
        ErrorHead   = '----------------------------------------- qMRLab Error';
        Tail = '\n-------------------------------------------------------|';
        


        
    end
    
    properties (SetAccess = private, GetAccess=public)
       
        Results = struct();
        
       
    end
    
    
    methods
        
        
        function obj = qmrstat()
            
            obj.Object.TestRetest =  test_retest({'Session-1','Session-2'});
            obj.Object.Correlation = correlation;
            %obj.Object.Concordance = concordance;
            
            
        end
        
     
        
        function obj = runPearsonCor(obj,crObj)
          
          % Change first line wrt nargin
          
          obj.Object.Correlation = crObj;
          obj = validate(obj,'Correlation');
          
          if obj.CorrelationValid
          
          %crObj = obj.Object.Correlation;
          
          % Mapnames can be multidim. 
           
          mp1 = crObj(1).getActiveMap();    
          mp2 = crObj(2).getActiveMap(); 
          VecX = mp1(obj.CorrelationJointMask);
          VecY = mp2(obj.CorrelationJointMask);
          
          % In correlation  class, there should be no NaN's under masked area
          % if exists, vals should be removed from both vectors. 
          
          [VecX,VecY] = qmrstat.cleanNan(VecX,VecY);
          
          [obj.Results.Correlation.Pearson.r, ...
          obj.Results.Correlation.Pearson.t, ...
          obj.Results.Correlation.Pearson.pval, ...
          obj.Results.Correlation.Pearson.hboot, ...
          obj.Results.Correlation.Pearson.CI] = ...
          Pearson(VecX,VecY,crObj(1).MapNames(crObj(1).ActiveMapIdx),crObj(2).MapNames(crObj(2).ActiveMapIdx),1);
          
          end
          
        end
        
        
        function obj = runSpearmanCor(obj)
          obj.Results.Correlation.Spearman.h = 1;
          obj.Results.Correlation.Spearman.p = 1;
          obj.Results.Correlation.Spearman.q = 1;
        end
        
        
        function obj = runRobustCor(obj)
          obj.Results.Correlation.Robust.h = 1;
          obj.Results.Correlation.Robust.p = 1;
          obj.Results.Correlation.Spearman.q = 1;
        end
        
        
    end
    
    
    
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
                        dimMis = boolMap;
                        for ii = 1:length(obj.Object.(name))
                        
                            obj.Object.(name)(ii) = obj.Object.(name)(ii).evalCompliance();
                            boolMap(ii) = obj.Object.(name)(ii).Compliance.noMapFlag;
                            boolMask(ii) = obj.Object.(name)(ii).Compliance.noMaskFlag;
                            if ~isempty(obj.Object.(name)(ii).StatMask)
                            dimMis(ii) = obj.Object.(name)(ii).Compliance.szMismatchFlag;
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
                    midx = find(boolMask==1);
                    obj.([name 'JointMask']) = obj.Object.(name)(midx).StatMask;
                    
                    % OPERATION BASED ON BOOLMASK INTRODUCES BUG HERE.
                    % JUST RETURN THE ONE THAT IS NOT EMPTY. BECAUSE IDX
                    % IS SKIPPED ABOVE
                    
                    
        end
        
        
        
        
    end
    
    
   methods(Static, Hidden)
       
      
       function [Vec1Out,Vec2Out] = cleanNan(Vec1, Vec2)
          
           joins = or(isnan(Vec1),isnan(Vec2));
           Vec1Out = Vec1(not(joins));
           Vec2Out = Vec2(not(joins));
           
           
       end
       
       
   end
    
    
end