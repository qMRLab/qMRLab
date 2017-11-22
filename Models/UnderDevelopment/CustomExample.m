classdef CustomExample % Name your Model
% CustomExample :  Describe the method here
%<a href="matlab: figure, imshow CustomExample.png ;">Pulse Sequence Diagram</a>
%
% Assumptions:
% (1)FILL
% (2) 
%
% Fitted Parameters:
%    Param1    
%    Param2    
%
% Non-Fitted Parameters:
%    residue                    Fitting residue.
%
% Options:
%   Q-space regularization      
%       Smooth q-space data per shell prior fitting
%
% Example of command line usage (see also <a href="matlab: showdemo Custom_batch">showdemo Custom_batch</a>):
%   For more examples: <a href="matlab: qMRusage(Custom);">qMRusage(Custom)</a>
%
% Author: 
%
% References:
%   Please cite the following if you use this module:
%     FILL
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

    properties
        MRIinputs = {'Data4D','Mask'}; % used in the data panel 
        
        % fitting options
        xnames = { 'Param1','Param2'}; % name of the parameters to fit
        voxelwise = 1; % 1--> input data in method 'fit' is 1D (vector). 0--> input data in method 'fit' is 4D.
        st           = [ 0.7	0.5 ]; % starting point
        lb            = [  0      0 ]; % lower bound
        ub           = [ 1        3 ]; % upper bound
        fx            = [ 0       0 ]; % fix parameters
        
        % Protocol
        Prot = struct('Data4D',... % Creates a Panel Data4D Protocol in Model Options menu
                        struct('Format',{{'TE' 'TR'}},... % columns name
                        'Mat', [rand(64,1) ones(64,1)])); % provide a default DKI protocol (Nx4 matrix)
        
        % Model options
        buttons = {'SMS',true,'Model',{'simple','advanced'}};
        options= struct();
        
    end
    
    methods
        function obj = CustomExample
            dbstop in CustomExample.m at 58
            obj.options = button2opts(obj.buttons); % converts buttons values to option structure
        end
        
        function Smodel = equation(obj, x)
            % Compute the Signal Model based on parameters x. 
            % x can be both a structure (FieldNames based on xnames) or a
            % vector (same order as xnames).
            x = struct2mat(x,obj.xnames);
            
            %% CHANGE HERE:
            D = zeros(1,2);
            D(1) = x(1); 
            D(2) = x(2);
            Tvec = obj.Prot.Data4D.Mat(:,1:2);
            
            % COMPUTE SIGNAL
            Smodel = exp(-D*Tvec');
        end
        
        function FitResults = fit(obj,data)
            %  Fit data using model equation.
            %  data is a structure. FieldNames are based on property
            %  MRIinputs. 
            
            if obj.options.SMS
                % buttons values can be access with obj.options
            end
            
            ydata = data.Data4D;
            [xopt, resnorm] = lsqcurvefit(@(x,xdata) obj.equation(addfix(obj.st,x,obj.fx)),...
                     obj.st(~obj.fx), [], ydata, obj.lb(~obj.fx), obj.ub(~obj.fx));
                 
            %  convert fitted vector xopt to a structure.
            FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),obj.xnames,1);
            FitResults.resnorm=resnorm;
        end
        
        
        function plotModel(obj, FitResults, data)
            %  Plot the Model and Data.
            if nargin<2, qMRusage(obj,'plotModel'), FitResults=obj.st; end

            Smodel = equation(obj, FitResults);
            Tvec = obj.Prot.Data4D.Mat(:,1:2); 
            [Tvec,Iorder] = sort(Tvec);
            plot(Tvec,Smodel(Iorder),'b-')
            if exist('data','var');
                hold on
                plot(Tvec(:,1),data.Data4D(Iorder),'r+')
                hold off
            end
            legend({'Model','Data'})
        end
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt, display)
            % Compute Smodel and plot
            Smodel = equation(obj, x);
            sigma = max(Smodel)/Opt.SNR;
            data.Data4D = random('rician',Smodel,sigma);
            FitResults = fit(obj,data);
            if display
                plotModel(obj, FitResults, data);
            end
        end

    end
end