classdef vfa_t1
% vfa_t1: Compute a T1 map using Variable Flip Angle
%
% Assumptions:
% 
% Inputs:
%   SPGR            spoiled Gradient echo data, 4D volume with different flip angles in time dimension
%   B1map           excitation (B1+) fieldmap. Used to correct flip angles.
%
% Outputs:
%   T1              Longitudinal relaxation time
%   M0              Equilibrium magnetization
%
% Protocol:
%   Array [nbFA x 2]:
%       [FA1 TR1; FA2 TR2;...]      flip angle [degrees] TR [s]
%
% Options:
%   None
%
% Example of command line usage (see also <a href="matlab: showdemo vfa_t1_batch">showdemo vfa_t1_batch</a>):
%   Model = vfa_t1;  % Create class from model 
%   Model.Prot.SPGR.Mat=[4 0.025; 10 0.025; 20 0.025]; %Protocol: 3 different FAs
%   data = struct;  % Create data structure 
%   data.SPGR = load_nii_data('SPGR.nii.gz');
%   data.B1map = load_nii_data('B1map.nii.gz');
%   FitResults = FitData(data,Model); %fit data
%   FitResultsSave_mat(FitResults);
%
%   For more examples: <a href="matlab: qMRusage(vfa_t1);">qMRusage(vfa_t1)</a>
%
% 
% Author: Ian Gagnon, 2017
%
% References:
%   Please cite the following if you use this module:
%     Fram, E.K., Herfkens, R.J., Johnson, G.A., Glover, G.H., Karis, J.P.,
%     Shimakawa, A., Perkins, T.G., Pelc, N.J., 1987. Rapid calculation of
%     T1 using variable flip angle gradient refocused imaging. Magn. Reson.
%     Imaging 5, 201?208
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG,
%     Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and
%     Stikov N. (2016), Quantitative magnetization transfer imaging made
%     easy with qMTLab: Software for data simulation, analysis, and
%     visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

properties (Hidden=true)
% Hidden proprties goes here.    
end

    properties
        MRIinputs = {'VFAData','B1map','Mask'};
        xnames = {'M0','T1'};
        voxelwise = 1;
        
        % Protocol
        Prot  = struct('SPGR',struct('Format',{{'FlipAngle' 'TR'}},...
                                         'Mat', [3 0.015; 20 0.015])); % You can define a default protocol here.
        
        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
methods (Hidden=true)
% Hidden methods goes here.    
end
    
    methods
        
        function obj = vfa_t1()
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
