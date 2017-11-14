classdef VFA_T1
    % Compute a T1 map using Variable Flip Angle
    %
    %-------------
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
    %   1) SPGR  : spoiled Gradient echo. 4D volume with variable flip angles
    %   2) B1map : excitation (B1+) fieldmap. Used to correct flip angles.
    %
    %-----------------------------------------------------------------------------------------------------
    %---------%
    % OUTPUTS %
    %---------%
    %	* T1 : Longitudinal relaxation time
    %	* M0 : ????
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
        MRIinputs = {'SPGR','B1map','Mask'};
        xnames = {'M0','T1'};
        voxelwise = 1;
        
        % Protocol
        Prot  = struct('SPGR',struct('Format',{{'Flip Angle' 'TR'}},...
                                         'Mat', [4 0.025; 10 0.025; 20 0.025])); % You can define a default protocol here.
        
        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = VFA_T1()
            obj.options = button2opts(obj.buttons);
        end
        
        function FitResult = equation(obj,x)
        end
        
        function FitResult = fit(obj,data)           
            % T1 and M0
            flipAngles = (obj.Prot.SPGR.Mat(:,1))';
            TR = obj.Prot.SPGR.Mat(:,2);
            if ~isfield(data,'B1map'), data.B1map=1; end
            [FitResult.M0, FitResult.T1] = mtv_compute_m0_t1(double(data.SPGR), flipAngles, TR(1), data.B1map);
       
        end
        
        function plotmodel(obj,x,data)
            x = mat2struct(x,obj.xnames);
            if isempty(data.B1map), data.B1map=1; end
            disp(x)
            flipAngles = (obj.Prot.SPGR.Mat(:,1))';
            TR = (obj.Prot.SPGR.Mat(1,2))';
            ydata = data.SPGR./sin(flipAngles/180*pi*data.B1map)';
            xdata = data.SPGR./tan(flipAngles/180*pi*data.B1map)';
            plot(xdata,ydata,'xb');
            hold on
            a = exp(-TR/x.T1);
            b = x.M0*(1-a);
            mval = min(xdata);
            Mval = max(xdata);
            plot([mval Mval],b+a*[mval Mval],'-r');
            hold off

%             h = plot( fitresult, xData, yData,'+');
%             set(h,'MarkerSize',30)
%             legend( h, 'y vs. x', 'untitled fit 1', 'Location', 'NorthEast' );
%             p11 = predint(fitresult,x,0.95,'observation','off');
%             hold on
%             plot(x,p11,'m--'); drawnow;
%             hold off
%             % Label axes
%             xlabel( 'x' );
%             ylabel( 'y' );
%             grid on
%             saveas(gcf,['temp.jpg']);
        end
        
    end
end
