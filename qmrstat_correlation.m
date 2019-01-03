 classdef qmrstat_correlation < AbstractStat
% Correlation family
% ===============================================================
properties

VariableID

end
% ===============================================================

methods

function obj = qmrstat_correlation(m,n)

  W = evalin('caller','whos');
  
  if not(moxunit_util_platform_is_octave)
  
  if nargin ~= 0

    % Row index identifies number of qmrstat_correlation objects
    % Column index identifies the number of correlation components included in
    % each qmrstat_correlation object.


    if (m >2 && n==1) || (m == 1 && n==1)
      error('Each qmrstat_object array should at least have two pairs.');
    end

    obj(m,n) = obj;

    for i = 1:m
      for j = 1:n
      obj(i,j).VariableID = [num2str(i) '::' num2str(j)];
      end
    end

  elseif nargin == 0 && ~(ismember('m',[W(:).name]) || ismember('n',[W(:).name]))

    obj = qmrstat_correlation(1,2);

  end
  
  else % Octave 
  
  % For obj arrays, static method qmrstat_correlation.objArray 
  
  end

end

function obj = loadStatMask(obj,input)
  % Note for developers: 
  % Overridden superclass method to load StatMask into all
  % objects simultaneously if the whole object array is passed.
  %
  % Individual objects can load masks as well. qmrstat.validation
  % will take care of it.

  W = evalin('caller','whos');

  if ~isempty(ismember(inputname(2),[W(:).name])) && all(ismember(inputname(2),[W(:).name]))


    if length(obj) >=2
        
      for ii = 1:length(obj)  
      obj(ii) = loadStatMask@AbstractStat(obj(ii),input);
      end

    elseif length(obj) ==1

      obj = loadStatMask@AbstractStat(obj,input);
    end

  else


    if length(obj) >=2
        
      for ii = 1:length(obj)  
      obj(ii) = loadStatMask@AbstractStat(obj(ii),eval('input'));
      end

    elseif length(obj) ==1

      obj = loadStatMask@AbstractStat(obj,eval('input'));

    end

  end

end





end % END PUBLIC METHODS
% ===============================================================

methods (Static)
    
    
     function obj = objArray(m,n)
     
         if m > 1
             error('qmrstat_correlation object arrays are 1XN');
         end
         
         obj(1)= qmrstat_correlation;
         
         if n>=2
            
             for ii = 2:n
                 obj(1,ii) = qmrstat_correlation;
             end
             
         end
         
     end
         
    
    
    
    
    
end
end % END CLASSDEF
