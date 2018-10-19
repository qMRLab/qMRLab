classdef correlation < AbstractStat
    
    
    properties
        
        SessionLabel
        
    end
    
    properties(SetAccess = private)
        
        PropHandle
        PropValue
        
    end
    
    methods
        
        function obj = correlation(F)
            
            W = evalin('caller','whos');
            
            if nargin ~= 0
                m = size(F,1);
                n = size(F,2);
                
                if (m == 1 && n>2) ||  (m >2 && n==1) || (m == 1 && n==1)
                    error('Correlation object arrays has a fixed length of two.');
                end
                
                obj(m,n) = obj;
                
                for i = 1:m
                    for j = 1:n
                        obj(i,j).SessionLabel = F(i,j);
                    end
                end
                
            elseif nargin == 0 && ~(ismember('F',[W(:).name]))
                
                obj = correlation({'Metric1','Metric2'});
                
            end
            
        end
        
        
        
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
end