% classdef TA_rget < TA_component
% 
%     methods
%         function obj=TA_rget
%             obj.Length=0;
%         end
%     end
% end

% classdef TA_rget < TA_component
%     properties
%         Prop=1;
%     end
% end

classdef TA_rget < FilterClass
    methods
        function obj = TA_rget
            obj.buttons;
            obj.options;
        end
    end
end