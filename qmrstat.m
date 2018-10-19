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
        
        % In correlation  class, there should be no NaN's under masked area
        % if exists, vals should be removed from both vectors. 
        
        function obj = runPearsonCor(obj)
          
          obj = validate(obj,'Correlation');
          
          obj.Results.Correlation.Pearson.h = 1;
          obj.Results.Correlation.Pearson.p = 1;
          obj.Results.Correlation.Pearson.q = 1;
          
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
                            dimMis(ii) = obj.Object.(name)(ii).Compliance.szMismatchFlag;
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
                    obj.([name 'JointMask']) = boolMask;
        end
        
        
        
        
    end
    
    
   
    
    
end