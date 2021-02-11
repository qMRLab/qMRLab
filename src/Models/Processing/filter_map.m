
classdef filter_map < AbstractModel & FilterClass
    % filter_map:   Applies spatial filtering (2D or 3D)
    %
    % Assumptions: If a 3D volume is provided and 2D filtering is requested, each slice will be processsed independently
    %
    % Inputs:
    %   Raw                Input data to be filtered
    %   (Mask)             Binary mask to exclude voxels from smoothing
    %
    % Outputs:
    %	Filtered           Filtered output map (see FilterClass.m for more info)
    %
    % Protocol:
    %	NONE
    %
    % Options:
    %   (inherited from FilterClass)
    %
    % Example of command line usage:
    %
    %   For more examples: <a href="matlab: qMRusage(filter_map);">qMRusage(filter_map)</a>
    %
    % Author: Ilana Leppert Dec 2018
    %
    % References:
    %   Please cite the following if you use this module:
    %     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
    %     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
    %     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343
    properties (Hidden=true)
        onlineData_url = 'https://osf.io/d8p4h/download?version=3';
    end
    
    properties
        MRIinputs = {'Raw','Mask'};
        xnames = {};
        voxelwise = 0; % 0, if the analysis is done matricially
        % 1, if the analysis is done voxel per voxel
        % Protocol
        Prot = struct();
    end
    % Inherit these from public properties of FilterClass
    % Model options
    % buttons ={};
    % options = struct(); % structure filled by the buttons. Leave empty in the code
    
    methods
        % Constructor
        function obj = filter_map()
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        function FitResult = fit(obj,data)
            % call the superclass (FilterClass) fit function
            FitResult.Filtered=cell2mat(struct2cell(fit@FilterClass(obj,data,[obj.options.Smoothingfilter_sizex,obj.options.Smoothingfilter_sizey,obj.options.Smoothingfilter_sizez])));
            % note: can't use struct2array because dne for octave...
        end
        
    end
    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            
        end
        
    end
    
end
    
