classdef CustomExample % Name your Model
    % ----------------------------------------------------------------------------------------------------
    % CustomExample :  Describe the method here
    % ----------------------------------------------------------------------------------------------------
    % Assumptions :
    % (1) 
    % (2) 
    % ----------------------------------------------------------------------------------------------------
    %
    %  Fitted Parameters:
    %    * D1 :    
    %    * D2 :    
    %
    %  Non-Fitted Parameters:
    %    * residue : Fitting residue.
    %
    %
    % Options:
    %   Q-space regularization : Smooth q-space data per shell prior fitting
    % ----------------------------------------------------------------------------------------------------
    % Written by: 
    % Reference: 
    % ----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'DiffusionData','Mask'}; % used in the data panel 
        
        % fitting options
        xnames = { 'D1','D2'}; % name of the parameters to fit
        voxelwise = 1; % 1--> input data in method 'fit' is 1D (vector). 0--> input data in method 'fit' is 4D.
        st           = [ 0.7	0.5 ]; % starting point
        lb            = [  0      0 ]; % lower bound
        ub           = [ 1        3 ]; % upper bound
        fx            = [ 0       0 ]; % fix parameters
        
        % Protocol
        Prot = struct('DiffusionData',... % Creates a Panel DiffusionData Protocol in Model Options menu
                        struct('Format',{{'Gx' 'Gy'  'Gz'   'bvalue'}},... % columns name
                        'Mat', [rand(64,3) linspace(0,2000,64)'])); % provide a default DKI protocol (Nx4 matrix)
        
        % Model options
        buttons = {'Qspace regularization',true,'Model',{'simple','advanced'},'SNR',50};
        options= struct();
        
    end
    
    methods
        function obj = CustomExample
            dbstop in CustomExample.m at 59
            obj = button2opts(obj); % converts buttons values to option structure
        end
        
        function Smodel = equation(obj, x)
            % Compute the Signal Model based on parameters x. 
            % x can be both a structure (FieldNames based on xnames) or a
            % vector (same order as xnames).
            
            % parse input
            if isstruct(x) % if x is a structure, convert to vector
                for ix = 1:length(obj.xnames)
                    xtmp(ix) = x.(obj.xnames{ix});
                end
                x = xtmp;
            end
            
            D = rand(3,3)*1e-3;
            %D(:) = x(??);
            bvalue=obj.Prot.DiffusionData.Mat(:,4);
            bvec = obj.Prot.DiffusionData.Mat(:,1:3);
            
            % COMPUTE SIGNAL
            Smodel = exp(-bvalue.*diag(bvec*D*bvec'));
        end
        
        function FitResults = fit(obj,data)
            %  Fit data using model equation.
            %  data is a structure. FieldNames are based on property
            %  MRIinputs. 
            
            if obj.options.QspaceRegularization
                % buttons values can be access with obj.options
            end
            
            ydata = data.DiffusionData;
            [xopt, resnorm] = lsqcurvefit(@(x,xdata) obj.equation(addfix(obj.st,x,obj.fx)),...
                     obj.st(~obj.fx), [], ydata, obj.lb(~obj.fx), obj.ub(~obj.fx));
                 
            %  convert fitted vector xopt to a structure.
            FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),obj.xnames,1);
            FitResults.resnorm=resnorm;
        end
        
        
        function plotmodel(obj, FitResults, data)
            %  Plot the Model and Data
            Smodel = equation(obj, FitResults);
            bvalue = obj.Prot.DiffusionData.Mat(:,4);
            plot(bvalue,Smodel,'b+')
            hold on
            plot(bvalue,data.DiffusionData,'r+')
            hold off
            legend({'Model','Data'})
        end
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, SNR)
            % Compute Smodel and plot
            Smodel = equation(obj, x);
            sigma = max(Smodel)/SNR;
            data.DiffusionData = random('rician',Smodel,sigma);
            FitResults = fit(obj,data);
            plotmodel(obj, FitResults, data);
        end

    end
end