classdef NODDI
    properties
        MRIinputs = {'MTdata','Mask'};
        xnames = { };
        
        % fitting options
        st           =  [ ]; % starting point
        lb            = [ ]; % lower bound
        ub           = [ ]; % upper bound
        fx            = [ ]; % fix parameters
        
        % Protocol
        ProtFormat ={'Gx' 'Gy'  'Gz'   '|G|'  'Delta'  'delta'  'TE'};
        Prot  = []; % You can define a default protocol here.
        
        % Model options
        buttons = {'model name',{'WatsonSHStickTortIsoV_B0','WatsonSHStickTortIsoVIsoDot_B0'}, 'Dcsf',3e-9};
        options= struct();
        
    end
    
    methods
        function [Smodel, fibredir] = equation(obj, x)
            if exist('MakeModel.m','file') ~= 2, errordlg('Please add the NODDI Toolbox to your Matlab Path: http://www.nitrc.org/projects/noddi_toolbox','NODDI is not installed properly'); return; end;
            
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
            
            
            Smodel = SynthMeas(obj.options.modelName, xsc, SchemeToProtocol(obj.Prot), fibredir, constants);
            
        end
        
        function FitResults = fit(obj,data)
            if exist('MakeModel.m','file') ~= 2, errordlg('Please add the NODDI Toolbox to your Matlab Path: http://www.nitrc.org/projects/noddi_toolbox','NODDI is not installed properly'); return; end
            % load model
            model = MakeModel(obj.options.modelName);
                        
%             isoIdx=GetParameterIndex(obj.options.modelName,'diso');
%             model.GD.fixed(isoIdx)=1; % gradient descent
%             model.GS.fixed(isoIdx)=1; % grid search
%             model.GS.fixedvals(isoIdx)=1e-9; model.GD.fixedvals(isoIdx)=1e-9;
            
            protocol = SchemeToProtocol(obj.Prot);
            
            % fit
            [xopt] = ThreeStageFittingVoxel(double(max(eps,data.MTdata)), protocol, model);

            % Outputs
            xnames = model.paramsStr;
            xnames{end+1} = 'ODI';
            xopt(end+1) = atan2(1, xopt(3)*10)*2/pi;
            FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),xnames,1);
        end
        
        function plotmodel(obj, x, data)
            if isstruct(x) % if x is a structure, convert to vector
                x = struct2array(x); x(end) = [];
            end
            [Smodel, fibredir]=obj.equation(x);
            Prot = ConvertProtUnits(obj.Prot);
            
            Gz=Prot(:,1:3)*fibredir(:);
            absc = Gz;
            [absc,II] = sort(absc); Prot = Prot(II,:); Smodel = Smodel(II);
            
            % plot
            if exist('data','var')
                data = data.MTdata(II);
                % plot data
                plot(absc,data,'bx')
                hold on
            end
            % plot model
            for iaq = unique(Prot(:,9))'
                plot(absc(Prot(:,9) == iaq),Smodel(Prot(:,9) == iaq),'r-')
            end

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
list_G=unique(round(Prot(:,4)*1e5)/1e5,'rows');
nnn = size(list_G,1);
for j = 1 : nnn
    for i = 1 : size(Prot,1)
        if  round(Prot(i,4)*1e5)/1e5 == list_G(j,:)
            Prot(i,9) = j;
        end
    end
end
end
