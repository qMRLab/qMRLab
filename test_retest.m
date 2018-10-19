classdef test_retest < AbstractStat
    
    % Temporary class
    
    properties
        
        SessionLabel
        
    end
    
    methods
        
        function obj = test_retest(F)
            
            W = evalin('caller','whos');
            
            if nargin ~= 0
                m = size(F,1);
                n = size(F,2);
                
                if m == n && n==1 
                    error('Test-retest is an object array with a mimimum length of two.');
                end
                
                obj(m,n) = obj;
                
                for i = 1:m
                    for j = 1:n
                        obj(i,j).SessionLabel = F(i,j);
                    end
                end
              
           
            elseif nargin == 0 && ~(ismember('F',[W(:).name]))
                
                warning('Test-retest object array should at least have 2 objects.');
                warning('Initializing new test_retest object containing two sessions: Session-1 and Session-2');
                obj = test_retest({'Session-1','Session-2'});
               
            end           
            
        end
        
    end
    
    
    % Hide some inhertired methods from user but keep functionality.
    
    methods (Hidden)
        
        
    end
    
    
end