classdef novifast < AbstractModel
% NOVIFAST: Non-linear T1 fit for Variable Flip Angle
%   This class is a light wrapper around NOVIFAST_IMAGE
%   See original package docs and examples in `External/novifast_v11`
%
% Assumptions:
%
% Inputs:
%   VFAData         Spoiled Gradient echo data, 4D volume with different flip angles in time dimension
%   (Mask)          Binary mask to accelerate the fitting. (OPTIONAL)
%
% Outputs:
%   T1              Longitudinal relaxation time [s]
%   M0              Equilibrium magnetization
%
% Protocol:
%   VFAData Array [nbFA x 2]:
%       [FA1 TR1; FA2 TR2;...]      flip angle [degrees] TR [s]
%                                   TR must be the same for all FAs.
% Options:
%   MaxIter: Maximum number of iterations. NOVIFAST will stop if the number of iterations exceeds 'MaxIter'
%   Tol: NOVIFAST will stop if the relative L1 norm difference between consecutive iterations is below 'Tol'
%   Direct: If Direct > 0, NOVIFAST will run 'Direct' iterations, without convergence criterion
%
% Example of command line usage:
%   Model = novifast;  % Create class from model
%   Model.Prot.VFAData.Mat=ProtLoad('Protocol.txt');
%   data = struct;  % Create data structure
%   data.VFAData = load_nii_data('VFAData.mat');
%   FitResults = FitData(data, Model); % fit data
%   FitResultsSave_mat(FitResults);
%
% References:
%   Please cite the following if you use this module:
%     G. Ramos-Llordén et al., "NOVIFAST: A Fast Algorithm for Accurate and
%     Precise VFA MRI T1 Mapping," in IEEE Transactions on Medical Imaging,
%     vol. 37, no. 11, pp. 2414-2427, Nov. 2018, doi: 10.1109/TMI.2018.2833288.
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F.,
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab:
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

properties (Hidden=true)
 onlineData_url = ''; % TBD
end

properties
    MRIinputs = {'VFAData','Mask'};
    xnames = {'M0','T1'};
    voxelwise = 0;

    % Default Protocol
    Prot = struct('VFAData', struct('Format',{{'FlipAngle' 'TR'}},...
        'Mat', [2 3 4 5 7 9 11 14 17 19 22; repmat(9,1,11)]'));
    % fitting options
    st = [500 0.5]; % starting point

    % Model options
    buttons = {'Tol', 1e-6, 'MaxIter', 10, 'Direct', 0};

    % Tiptool descriptions
    tips = {'Tol', 'Convergence criterion: Max. L1 norm difference between consecutive iterations',...
            'MaxIter', 'Maximum number of iterations',...
            'Direct', 'If Direct = N > 0 is provided, NOVIFAST will run in "blind" mode, running N iterations regardless of Tol / MaxIter'};

    options= struct(); % structure filled by the buttons. Leave empty in the code

    % Simulation Options
    Sim_Single_Voxel_Curve_buttons = {'SNR',50};
    Sim_Optimize_Protocol_buttons = {'# of volumes',5,'Population size',100,'# of migrations',100};
end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods
        function obj = novifast()
            obj.options = button2opts(obj.buttons);
        end

       function FitResult = fit(obj,data)
            % T1 and M0
            flipAngles = (obj.Prot.VFAData.Mat(:,1));
            TR = obj.Prot.VFAData.Mat(:,2);

            opts = obj.options;
            if opts.Direct == 0
                opts = rmfield(opts,'Direct');
            end

            if obj.voxelwise == 0
                if (length(unique(TR))~=1), error('VFA data must have same TR'); end

                if ismatrix(data.VFAData)
                    % plotfit sends a squeezed voxel
                    data.VFAData = shiftdim(data.VFAData(:),-3);
                end
                if ~isfield(data, 'Mask') || isempty(data.Mask), data.Mask = ones(size(data.VFAData,1:3)); end

                [ m0, t1 ] = novifast_image( data.VFAData, flipAngles, TR(1), opts, fliplr(obj.st), data.Mask);

                FitResult.T1 = t1;
                FitResult.M0 = m0;

            elseif obj.voxelwise == 1

                [ m0, t1 ] = novifast_1D( data.VFAData, flipAngles, TR(1), opts , fliplr(obj.st) );
                FitResult.T1 = t1;
                FitResult.M0 = m0;
            end
       end

       function plotModel(obj,x,data)
            if nargin<2 || isempty(x), x = obj.st; end
            x = mat2struct(x,obj.xnames);
            disp(x)
            flipAngles = obj.Prot.VFAData.Mat(:,1)';
            TR = obj.Prot.VFAData.Mat(1,2)';

            if exist('data','var')
                % Plot data and fitted signal
                plot(flipAngles,data.VFAData,'.','MarkerSize',16, 'DisplayName','data')
            end

            fa = linspace(min(flipAngles), max(flipAngles), 100);
            cfa = cos(fa/180*pi);
            sfa = sin(fa/180*pi);
            Smodel = @(M0, T1) M0*sfa.*(1-exp(-TR/T1))./(1-exp(-TR/T1)*cfa);

            hold on
            plot(fa,Smodel(x.M0, x.T1),'-', ...
                'DisplayName',sprintf('novifast: T1=%0.1f s, M0=%0.1f',x.T1,x.M0));

            if exist('data','var')
                % Compare with linear fit
                lobj = vfa_t1();
                lobj.Prot.VFAData.Mat = obj.Prot.VFAData.Mat;
                LF = lobj.fit(data);

                plot(fa,Smodel(LF.M0, LF.T1),'-', ...
                    'DisplayName',sprintf('linear: T1=%0.1f s, M0=%0.1f',LF.T1,LF.M0));
            end
            hold off
            xlabel('Flip Angle [deg]','FontSize',12);
            ylabel('Signal','FontSize',12);
            legend('Location','best')
            set(gca,'FontSize',12)
       end
    end

    % CLI-only implemented static methods. Can be called directly from
    % class - no object needed.
    methods(Static)
    end
end
