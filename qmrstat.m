classdef qmrstat
    
    
    properties
        
        Object      
        
    end
    
    properties (SetAccess = private, GetAccess=public)
       
        Results = struct();
        
       
    end
    
    
    methods
        
        
        function obj = qmrstat()
            
            obj.Object.TestRetest =  test_retest({'Session-1','Session-2'});
            obj.Object.Correlation = correlation;
            
            
        end
        
        
        function obj = runPearsonCor(obj)
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
    
    
    
    
    
    
    
    
    
end