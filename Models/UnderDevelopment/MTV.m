classdef MTV
%-----------------------------------------------------------------------------------------------------
% MTV :  Macromolecular Tissue Volume
%-----------------------------------------------------------------------------------------------------
%-------------%
% ASSUMPTIONS %
%-------------% 
% (1) FILL
% (2) 
% (3) 
% (4) 
%-----------------------------------------------------------------------------------------------------
%--------%
% INPUTS %
%--------%
%   1) SPGR    : Spoiled Gradient Echo data
%   2) B1map   : Excitation (B1+) field map. Used to correct flip angle
%   3) CSFMask : CerebroSpinal Fluid Mask. Used for proton density
%                normalization (assuming ProtonCSF = 1)
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OUTPUTS %
%---------%
%	* T1       : Longitudinal relaxation time
%	* CoilGain : Reception profile of the antenna (B1- map)
%	* PD       : Proton Density
%	* MTV      : Macromolecular Tissue Volume
%
%-----------------------------------------------------------------------------------------------------
%----------%
% PROTOCOL %
%----------%
%	* Flip Angle (degree)
%	* TR : Repetition time of the whole sequence (s)
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OPTIONS %
%---------%
%   NONE
%
%-----------------------------------------------------------------------------------------------------
% Written by: Ian Gagnon, 2017
% Reference: FILL
%-----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'SPGR','B1map','CSFMask'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct('MTV',struct('Format',{{'Flip Angle' 'TR'}},...
                                     'Mat', [4 0.025; 10 0.025; 20 0.025])); % You can define a default protocol here.
        
        % Model options
        buttons = {'PANEL','CoilGain_Fitting',4,...
                    'Polynomial',true,'Order',{'1','2','3','4','5','6','7','8','9','10'},...
                    'Spline',false,'Smoothness',10};
        options = struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = MTV
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
            if obj.options.CoilGain_Fitting_Polynomial && obj.options.CoilGain_Fitting_Spline
                obj.options.CoilGain_Fitting_Polynomial = false;
                obj.options.CoilGain_Fitting_Spline = false;
            end   
        end
        
        function FitResult = fit(obj,data)           
            % T1 and M0
            flipAngles = (obj.Prot.MTV.Mat(:,1))';
            TR = obj.Prot.MTV.Mat(1,2);
            [M0, FitResult.T1] = mtv_compute_m0_t1(double(data.SPGR), flipAngles(1:length(flipAngles)), TR, data.B1map);
            
            %[PD,coilgain] = mtv_correct_receive_profile_v2( fname_M0, fname_T1, WMMask, CSFMask , smoothness, pixdim);

            % CoilGain           
            % Option 1: Polynomial 
            if obj.options.CoilGain_Fitting_Polynomial
                Order = str2double(obj.options.CoilGain_Fitting_Order);
                FitResult.CoilGain = mtv_fit3dpolynomialmodel(M0,data.CSFMask,Order);
            % Option 2: Spline   
            elseif obj.options.CoilGain_Fitting_Spline
                Smoothness = obj.options.CoilGain_Fitting_Smoothness;
                if any(size(data.SPGR) == 1)
                    if isfield(data,'hdr') 
                        Spacing = data.hdr.dime.pixdim(2:3); 
                    else
                        Spacing = [0.5 0.5];
                    end
                else
                    if isfield(data,'hdr') 
                        Spacing = data.hdr.dime.pixdim(2:4); 
                    else
                        Spacing = [0.5 0.5 0.5];
                    end
                end
                FitResult.CoilGain= mtv_fit3dsplinemodel(M0, data.CSFMask, [], Smoothness, Spacing);
            else
                errordlg('You must chose a CoilGain fitting option!','Error');                
            end
            
            %PD
            FitResult.PD = M0./FitResult.CoilGain;
            
            % MTV
            PDwater = mean(FitResult.PD(logical(data.CSFMask)));
            PD = FitResult.PD/PDwater;
            FitResult.MTV = 1 - PD;          
        end
        
    end
end