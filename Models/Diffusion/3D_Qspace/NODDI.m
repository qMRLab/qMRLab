classdef NODDI
    properties
        MRIinputs = {'DiffusionData','Mask'};
        xnames = { };
        
        % fitting options
        st           =  [ ]; % starting point
        lb            = [ ]; % lower bound
        ub           = [ ]; % upper bound
        fx            = [ ]; % fix parameters
        
        % Protocol
        Prot = struct('DiffusionData',struct('Format',{{'Gx' 'Gy'  'Gz'   '|G|'  'Delta'  'delta'  'TE'}},...
                                      	     'Mat',  txt2mat('DefaultProtocol_NODDI.scheme'))); % You can define a default protocol here.
        
        % Model options
        buttons = {'model name',{'WatsonSHStickTortIsoV_B0','WatsonSHStickTortIsoVIsoDot_B0'}};
        options= struct();
        
    end
    
    methods
        function obj = NODDI
            if exist('MakeModel.m','file') ~= 2, errordlg('Please add the NODDI Toolbox to your Matlab Path: http://www.nitrc.org/projects/noddi_toolbox','NODDI is not installed properly'); return; end;
            obj = button2opts(obj);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
            model = MakeModel(obj.options.modelName);
            Pindex=~ismember(model.paramsStr,{'b0','theta','phi'});
            obj.xnames = model.paramsStr(Pindex);
            obj.fx = model.GD.fixed(Pindex);
            grid = GetSearchGrid(obj.options.modelName, model.tissuetype, false(1,sum(Pindex)), false(1,sum(Pindex)));
            scale = GetScalingFactors(obj.options.modelName);
            obj.st = model.GD.fixedvals(Pindex).*scale(Pindex);
            obj.lb = min(grid,[],2)'.*scale(Pindex);
            obj.ub = max(grid,[],2)'.*scale(Pindex);
        end
        
        function [Smodel, fibredir] = equation(obj, x)
            if isstruct(x) % if x is a structure, convert to vector
                if isfield(x,'ODI'), x = rmfield(x,'ODI'); end
                x = struct2array(x);
            end
            
            model = MakeModel(obj.options.modelName);
            if length(x)<length(model.GD.fixedvals)-2, x(end+1)=1; end % b0
            if length(x)<length(model.GD.fixedvals)-1, x(end+1)=0; x(end+1)=0; end % phi and theta
            
            scale = GetScalingFactors(obj.options.modelName);
            if (strcmp(obj.options.modelName, 'ExCrossingCylSingleRadGPD') ||...
                    strcmp(obj.options.modelName, 'ExCrossingCylSingleRadIsoDotTortIsoV_GPD_B0'))
                xsc = x(1:(end-4))./scale(1:(end-1));
                theta = [x(end-3) x(end-1)]';
                phi = [x(end-2) x(end)]';
                fibredir = [cos(phi).*sin(theta) sin(phi).*sin(theta) cos(theta)]';
            else
                xsc = x(1:(end-2))./scale(1:(end-1));
                theta = x(end-1);
                phi = x(end);
                fibredir = [cos(phi)*sin(theta) sin(phi)*sin(theta) cos(theta)]';
            end
            constants.roots_cyl = BesselJ_RootsCyl(30);
            
            
            Smodel = SynthMeas(obj.options.modelName, xsc, SchemeToProtocol(obj.Prot.DiffusionData.Mat), fibredir, constants);
            
        end
        
        function FitResults = fit(obj,data)
            if exist('MakeModel.m','file') ~= 2, errordlg('Please add the NODDI Toolbox to your Matlab Path: http://www.nitrc.org/projects/noddi_toolbox','NODDI is not installed properly'); return; end
            % load model
            model = MakeModel(obj.options.modelName);
            Pindex=~ismember(model.paramsStr,{'b0','theta','phi'});            
            model.GD.fixed(Pindex)=obj.fx; % gradient descent
            model.GS.fixed(Pindex)=obj.fx; % grid search
            scale = GetScalingFactors(obj.options.modelName);
            model.GS.fixedvals(Pindex)=obj.st./scale(Pindex);
            model.GD.fixedvals(Pindex)=obj.st./scale(Pindex);
            
            protocol = SchemeToProtocol(obj.Prot.DiffusionData.Mat);
            
            % fit
            [xopt] = ThreeStageFittingVoxel(double(max(eps,data.DiffusionData)), protocol, model);

            % Outputs
            xnames = model.paramsStr;
            xnames{end+1} = 'ODI';
            xopt(end+1) = atan2(1, xopt(3)*10)*2/pi;
            FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),xnames,1);
        end
        
        function plotmodel(obj, x, data)
            [Smodel, fibredir]=obj.equation(x);
            Prot = ConvertProtUnits(obj.Prot.DiffusionData.Mat);
                        
            % plot
            if exist('data','var')
                h = scd_display_qspacedata3D(data.DiffusionData,Prot,fibredir);
                hold on
                % remove data legends
                for iD = 1:length(h)
                    hAnnotation = get(h(iD),'Annotation');
                    hLegendEntry = get(hAnnotation','LegendInformation');
                    set(hLegendEntry,'IconDisplayStyle','off');
                end
            end
            
            % plot fitting curves
            scd_display_qspacedata3D(Smodel,Prot,fibredir,'none','-');
           
            hold off
            
        end
        
        function plotProt(obj)
            % round bvalue
            Prot = obj.Prot.DiffusionData.Mat;
            Prot(:,4)=round(scd_scheme2bvecsbvals(Prot)*100)*10;
            % display
            scd_scheme_display(Prot)
            subplot(2,2,4)
            scd_scheme_display_3D_Delta_delta_G(ConvertProtUnits(obj.Prot.DiffusionData.Mat))
        end

        function FitResults = Sim_Single_Voxel_Curve(obj, x, SNR,display)
            if ~exist('display','var'), display=1; end
            [Smodel, fibredir] = equation(obj, x);
            sigma = max(Smodel)/SNR;
            data.DiffusionData = random('rician',Smodel,sigma);
            FitResults = fit(obj,data);
            if display
                plotmodel(obj, FitResults, data);
                hold on
                Prot = ConvertProtUnits(obj.Prot.DiffusionData.Mat);
                h = scd_display_qspacedata3D(Smodel,Prot,fibredir,'o','none');
                set(h,'LineWidth',.5)
            end
        end
        
        function SimVaryResults = Sim_Sensitivity_Analysis(obj, SNR, runs, OptTable)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, SNR, runs, OptTable);
            
        end
        
    end
end


function protocol = SchemeToProtocol(Prot)
%
% Reads a Camino Version 1 schemefile into a protocol object
%
% function protocol = SchemeToProtocol(schemefile)
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang     (gary.zhang@ucl.ac.uk)
%

Prot = Prot';

% Create the protocol
protocol.pulseseq = 'PGSE';
protocol.grad_dirs = Prot(1:3,:)';
protocol.G = Prot(4,:);
protocol.delta = Prot(5,:);
protocol.smalldel = Prot(6,:);
protocol.TE = Prot(7,:);
protocol.totalmeas = length(Prot);

% Find the B0's
bVals = GetB_Values(protocol);
protocol.b0_Indices = find(bVals==0);

end

function Prot = ConvertProtUnits(Prot)
% convert units
Prot(:,4)=Prot(:,4).*sqrt(sum(Prot(:,1:3).^2,2))*1e-3; % G mT/um
Prot(:,1:3)=Prot(:,1:3)./repmat(sqrt(Prot(:,1).^2+Prot(:,2).^2+Prot(:,3).^2),1,3); Prot(isnan(Prot))=0;
Prot(:,5) = Prot(:,5)*10^3; % DELTA ms
Prot(:,6) = Prot(:,6)*10^3; % delta ms
Prot(:,7) = Prot(:,7)*10^3; % TE ms
gyro = 42.57; % kHz/mT
Prot(:,8) = gyro*Prot(:,4).*Prot(:,6); % um-1

% Find different shells
list_G=unique(round(Prot(:,[4 5 6 7])*1e5)/1e5,'rows');
nnn = size(list_G,1);
for j = 1 : nnn
    for i = 1 : size(Prot,1)
        if  min(round(Prot(i,[4 5 6 7])*1e5)/1e5 == list_G(j,:))
            Prot(i,9) = j;
        end
    end
end
Prot(ismember(Prot(:,9),find(list_G(:,1)==0)),9) = find(list_G(:,1)==0,1,'first');
end
