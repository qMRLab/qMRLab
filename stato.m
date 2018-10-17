classdef stato < AbstractStat
   
    % Temporary class
    
    properties 
    end
    
    methods 
        
        function obj = stato()
            disp('init');
        end
        
    end
    
    
    % Hide some inhertired methods from user but keep functionality. 

    methods (Hidden)
        
       function obj = getStatMask(obj,input)
           
           % Normally not this tricky. 
           
           W = evalin('caller','whos');
           
           if ~isempty(ismember(inputname(2),[W(:).name])) && all(ismember(inputname(2),[W(:).name]))
          obj = getStatMask@AbstractStat(obj,input);
           else
         obj = getStatMask@AbstractStat(obj,eval('input'));
           end
      end 
        
    end

    
end