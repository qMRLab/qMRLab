classdef MethodBrowser < FileBrowser
    %MethodBrowser Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ItemsList; % is a list of the class BrowserSet objects
        NbItems;
        MethodID;        
    end
    
    methods
        % constructor
        function obj = MethodBrowser(varargin)
            parent = varargin{1};
            obj@FileBrowser(parent); 
            if nargin > 2            
                parent = varargin{1};
                handles = varargin(2);
                Params = varargin{3}; 
                
                obj.MethodID = Params(1);
                Location = [0.02, 0.7];
                
                TheSize = size(Params);
                obj.NbItems = TheSize(2)-2;
                
                obj.ItemsList = repmat(BrowserSet(),1,obj.NbItems);
                
                for i=1:obj.NbItems
                    obj.ItemsList(i) = BrowserSet(parent, handles, Params(i+1), Location, 1, 1);
                    Location = Location + [0.0, -0.15];
                end
            end
            
            
        end % end constructor      
        
        function VisibleOn(obj)
            for i=1:obj.NbItems
                obj.ItemsList(i).VisibleOn;
            end
        end
        
        function VisibleOff(obj)
            for i=1:obj.NbItems
                obj.ItemsList(i).VisibleOff;
            end
        end
        
        function Res = IsMethod(obj, NameID)
            if strcmp(obj.MethodID, NameID)
                Res = 0;
            else
                Res = 1;
            end
        end
    end
    
end

