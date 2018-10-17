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
           
           % Normally not this tricky. getStatMask method works with 
           % i)   variable from workspace
           % ii)  a file name 
           % iii) a directory 
           % getStatMask@AbstractStat call is different than calling it 
           % directly. Note that this function is not hidden in the
           % superclass. This is why wrapping is neccesary.
           % For other methods this is way more easier. 
           
           W = evalin('caller','whos');
           
           if ~isempty(ismember(inputname(2),[W(:).name])) && all(ismember(inputname(2),[W(:).name]))
          obj = getStatMask@AbstractStat(obj,input);
           else
         obj = getStatMask@AbstractStat(obj,eval('input'));
           end
      end 
        
    end

    
end