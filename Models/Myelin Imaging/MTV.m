classdef MTV
% ----------------------------------------------------------------------------------------------------
% MTV :  Macromolecular Tissue Volume
% ----------------------------------------------------------------------------------------------------
% Assumptions :
% FILL
% ----------------------------------------------------------------------------------------------------
%
%  Output Parameters:
%    * MTV
%    * T1
%
%
%  Non-Fitted Parameters:
%    *     
%    * FILL
%
%
% Options:
%   FILL:
%     *
%     *
%   FILL:
%     * 
%     * 
% ----------------------------------------------------------------------------------------------------
% Written by: I. Gagnon, 2017
% Reference: FILL
% ----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'SPGR','B1','CSFMask'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct('MTV',struct('Format',{{'Flip Angle' 'TR'}},...
                                     'Mat', [4 0.025; 10 0.025; 20 0.025])); % You can define a default protocol here.
        
        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = MTV
            obj = button2opts(obj);
        end
        
        function FitResult = fit(obj,data)           
            % T1 and M0
            flipAngles = (obj.Prot.MTV.Mat(:,1))';
            TR = obj.Prot.MTV.Mat(1,2);
            [M0, FitResult.T1] = mtv_compute_m0_t1(double(data.SPGR(:,:,:,:)), flipAngles(1:length(flipAngles)), TR, data.B1);
            
            %[PD,coilgain] = mtv_correct_receive_profile_v2( fname_M0, fname_T1, WMMask, CSFMask , smoothness, pixdim);

            % Coil gain and PD
            % Opt1: spline. 
            %   smoothness (>0)
            %   FitResult.coilgain= mtv_fit3dsplinemodel(M0,data.CSFMask,[],smoothness);
            % Opt2: Polynome.
            order = 1;
            FitResult.coilgain= mtv_fit3dpolynomialmodel(M0,data.CSFMask,order);
            FitResult.PD = M0./coilgain;
            
            % MTV
            PDwater = mean(FitResult.PD(logical(data.CSFMask)));
            PD = FitResult.PD/PDwater;
            FitResult.MTV = 1-PD;          
        end
        
    end
end