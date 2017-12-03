classdef noddi < AbstractModel
% noddi:   Neurite Orientation Dispersion and Density Imaging
%          Three-compartment model for fitting multi-shell DWI
%<a href="matlab: figure, imshow noddi.png ;">Pulse Sequence Diagram</a>
%           
% ASSUMPTIONS:
%   Neuronal fibers model:
%     geometry                          sticks (Dperp = 0)
%     Orientation dispersion            YES (Watson distribution). Note that NODDI is more robust to
%                                                                   crossing fibers that DTI  (Campbell, NIMG 2017)
%
%     Permeability                      NO
%   Diffusion properties:
%     intra-axonal                      totally restricted
%       diffusion coefficient (Dr)      fixed by default.
%     extra-axonal                      Tortuosity model. Parallel diffusivity is equal to
%                                         intra-diffusivity.Perpendicular diffusivity is 
%                                         proportional to fiber density
%       diffusion coefficient (Dh)      Constant
%
% Inputs:
%   DiffusionData       4D diffusion weighted dataset
%
% Outputs:
%   di                  Diffusion coefficient in the restricted compartment.
%   ficvf               Fraction of water in the restricted compartment.
%   fiso                Fraction of water in the isotropic compartment (e.g. CSF/Veins)
%   fr                  Fraction of restricted water in the entire voxel (e.g. intra-cellular volume fraction)
%                        fr = ficvf*(1-fiso)
%   diso (fixed)        diffusion coefficient of the isotropic compartment (CSF)
%   kappa               Orientation dispersion index                               
%   b0                  Signal at b=0
%   theta               angle of the fibers
%   phi                 angle of the fibers
%
% Protocol:
%   Multi-shell diffusion-weighted acquisition
%    at least 2 non-zeros bvalues
%    at least 5 b=0 (used to compute noise standard deviation
%
%   DiffusionData       Array [NbVol x 7]
%     Gx                Diffusion Gradient x
%     Gy                Diffusion Gradient y
%     Gz                Diffusion Gradient z
%     Gnorm (T/m)         Diffusion gradient magnitude
%     Delta (s)         Diffusion separation
%     delta (s)         Diffusion duration
%     TE (s)            Echo time
%
% Options:
%   Model               Model part of NODDI. 
%                         Available models are:
%                           -WatsonSHStickTortIsoVIsoDot_B0 is a four model compartment used for ex-vivo datasets
%
% Example of command line usage (see also <a href="matlab: showdemo noddi_batch">showdemo noddi_batch</a>):
%   For more examples: <a href="matlab: qMRusage(noddi);">qMRusage(noddi)</a>
%
% Author: Tanguy Duval
%
% References:
%   Please cite the following if you use this module:
%     Zhang, H., Schneider, T., Wheeler-Kingshott, C.A., Alexander, D.C., 2012. NODDI: practical in vivo neurite orientation dispersion and density imaging of the human brain. Neuroimage 61, 1000?1016.
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

properties (Hidden=true)
    onlineData_url = 'https://osf.io/4s6rf/download/';
end

    properties
        MRIinputs = {'DiffusionData','Mask'};
        xnames = { };
        voxelwise = 1;
        
        % fitting options
        st           = [ ]; % starting point
        lb           = [ ]; % lower bound
        ub           = [ ]; % upper bound
        fx           = [ ]; % fix parameters
        
        % Protocol
        Prot = struct('DiffusionData',struct('Format',{{'Gx' 'Gy'  'Gz'   'Gnorm'  'Delta'  'delta'  'TE'}},...
                                      	     'Mat',   txt2mat(fullfile(fileparts(which('qMRLab.m')),'Models_Functions', 'NODDIfun', 'Protocol.txt'),'InfoLevel',0))); % You can define a default protocol here.
        
        % Model options
        buttons = {'model name',{'WatsonSHStickTortIsoV_B0','WatsonSHStickTortIsoVIsoDot_B0'}};
        options= struct();
        
    end
    
methods (Hidden=true)
% Hidden methods goes here.    
end
    
    methods
        function obj = noddi
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
            if exist('MakeModel.m','file') ~= 2, errordlg('Please add the NODDI Toolbox to your Matlab Path: http://www.nitrc.org/projects/noddi_toolbox','NODDI is not installed properly'); return; end;
            model      = MakeModel(obj.options.modelname);
            Pindex     =~ ismember(model.paramsStr,{'b0','theta','phi'});

            if isempty(obj.xnames) || ~isequal(obj.xnames,model.paramsStr)
                ModelChanged=true;
            else
                ModelChanged=false;
            end
            
            obj.xnames = model.paramsStr;
            grid       = GetSearchGrid(obj.options.modelname, model.tissuetype, false(1,sum(Pindex)), false(1,sum(Pindex)));
            scale      = GetScalingFactors(obj.options.modelname);
            
            obj.lb     = min(grid,[],2)'.*scale(Pindex);
            obj.ub     = max(grid,[],2)'.*scale(Pindex);
            
            % for simulation:
            obj.lb(strcmp(obj.xnames,'b0'))=0; 
            obj.lb(strcmp(obj.xnames,'theta'))=0; 
            obj.lb(strcmp(obj.xnames,'phi'))=0;
            obj.ub(strcmp(obj.xnames,'b0'))=1e3; 
            obj.ub(strcmp(obj.xnames,'theta'))=pi; 
            obj.ub(strcmp(obj.xnames,'phi'))=pi;
            
            if ModelChanged % user can modify this
                obj.fx     = model.GD.fixed;
                obj.st     = model.GD.fixedvals(Pindex).*scale(Pindex);
                obj.st(strcmp(obj.xnames,'b0'))=1;
                obj.st(strcmp(obj.xnames,'theta'))=.2; % at theta=0, phi can have any value, not good for testing
                obj.st(strcmp(obj.xnames,'phi'))=0;
                obj.st(ismember(model.paramsStr,{'ficvf'})) = .5;
            end
            
            obj.st     = max(obj.st,obj.lb);
            obj.st     = min(obj.st,obj.ub);

        end
        
        function [Smodel, fibredir] = equation(obj, x)
            x = struct2mat(x,obj.xnames); % if x is a structure, convert to vector
            
            model = MakeModel(obj.options.modelname);
            if length(x)<length(model.GD.fixedvals)-2, x(end+1) = 1; end % b0
            if length(x)<length(model.GD.fixedvals)-1, x(end+1) = 0; x(end+1)=0; end % phi and theta
            
            scale = GetScalingFactors(obj.options.modelname);
            if (strcmp(obj.options.modelname, 'ExCrossingCylSingleRadGPD') ||...
                strcmp(obj.options.modelname, 'ExCrossingCylSingleRadIsoDotTortIsoV_GPD_B0'))
                xsc      = x(1:(end-4))./scale(1:(end-1));
                theta    = [x(end-3) x(end-1)]';
                phi      = [x(end-2) x(end)]';
                fibredir = [cos(phi).*sin(theta) sin(phi).*sin(theta) cos(theta)]';
            else
                xsc      = x(1:(end-2))./scale(1:(end-1));
                theta    = x(end-1);
                phi      = x(end);
                fibredir = [cos(phi)*sin(theta) sin(phi)*sin(theta) cos(theta)]';
            end
            constants.roots_cyl = BesselJ_RootsCyl(30);
            
            Smodel = SynthMeas(obj.options.modelname, xsc, SchemeToProtocolmat(obj.Prot.DiffusionData.Mat), fibredir, constants);
            
        end
        
        function FitResults = fit(obj,data)
            if exist('MakeModel.m','file') ~= 2, errordlg('Please add the NODDI Toolbox to your Matlab Path: http://www.nitrc.org/projects/noddi_toolbox','NODDI is not installed properly'); return; end
            % load model
            model = MakeModel(obj.options.modelname);
            model.GD.fixed = obj.fx; % gradient descent
            model.GS.fixed = obj.fx; % grid search
            Pindex     =~ ismember(model.paramsStr,{'theta','phi'});
            scale = ones(1,length(obj.xnames));
            scaletmp = GetScalingFactors(obj.options.modelname);
            scale(Pindex) = scaletmp(1:end-1);
            model.GS.fixedvals = obj.st./scale;
            model.GD.fixedvals = obj.st./scale;
            
            protocol = SchemeToProtocolmat(obj.Prot.DiffusionData.Mat);
            
            % fit
            [gsps, fobj_gs, mlps, fobj_ml, error_code] = ThreeStageFittingVoxel(max(eps,double(data.DiffusionData)), protocol, model);
            xopt = mlps;
            % Outputs
            xnames = model.paramsStr;
            if sum(strcmp(obj.xnames,'ficvf')) && sum(strcmp(obj.xnames,'fiso'))
                xnames{end+1} = 'fr';
                xopt(end+1)   = xopt(strcmp(obj.xnames,'ficvf'))*(1-xopt(strcmp(obj.xnames,'fiso')));
            end
            xnames{end+1} = 'ODI';
            xopt(end+1)   = atan2(1, xopt(strcmp(obj.xnames,'kappa'))*10)*2/pi;
            xnames{end+1} = 'ObjectiveFun';
            xopt(end+1)   = fobj_ml;
            FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),xnames,1);
        end
        
        function plotModel(obj, x, data)
            if nargin<2, x=obj.st; end
            [Smodel, fibredir] = obj.equation(x);
            Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,1,1);
                        
            % plot
            if exist('data','var')
                h = scd_display_qspacedata3D(data.DiffusionData,Prot,fibredir);
                hold on
                % remove data legends
                for iD = 1:length(h)
                    if ~moxunit_util_platform_is_octave
                        hAnnotation = get(h(iD),'Annotation');
                        hLegendEntry = get(hAnnotation','LegendInformation');
                        set(hLegendEntry,'IconDisplayStyle','off');
                    end
                end
            end
            
            % plot fitting curves
            scd_display_qspacedata3D(Smodel,Prot,fibredir,'none','-');
           
            hold off
            
        end
        
        function plotProt(obj)
            % round bvalue
            Prot      = obj.Prot.DiffusionData.Mat;
            Prot(:,4) = round(scd_scheme2bvecsbvals(Prot)*100)*10;
            % display
            scd_scheme_display(Prot)
            subplot(2,2,4)
            scd_scheme_display_3D_Delta_delta_G(ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,1,1))
        end

        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            if ~exist('display','var'), display=1; end
            if nargin<3, Opt.SNR = 200; end
            [Smodel, fibredir] = equation(obj, x);
            sigma = max(Smodel)/Opt.SNR;
            data.DiffusionData = ricernd(Smodel,sigma);
            FitResults = fit(obj,data);
            if display
                plotModel(obj, FitResults, data);
                hold on
                Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,1,1);
                h = scd_display_qspacedata3D(Smodel,Prot,fibredir,'o','none');
                set(h,'LineWidth',.5)
            end
        end
        
        function SimVaryResults = Sim_Sensitivity_Analysis(obj, OptTable, Opt)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, Opt.Nofrun, OptTable, Opt);
            
        end
        
        function SimRndResults = Sim_Multi_Voxel_Distribution(obj, RndParam, Opt)
            % SimVaryGUI
            SimRndResults = SimRnd(obj, RndParam, Opt);
        end

    end
    
    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            obj.Prot.DiffusionData.Format{5}='Gnorm (T/m)'; % old: '|G| (T/m)'
        end
    end

end
