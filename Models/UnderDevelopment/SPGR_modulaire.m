classdef SPGR_modulaire
    % ----------------------------------------------------------------------------------------------------
    % SPGR :  qMT using Spoiled Gradient Echo (or FLASH)
    % ----------------------------------------------------------------------------------------------------
    % Assumptions :
    % (1) FILL
    % (2)
    % (3)
    % (4)
    % ----------------------------------------------------------------------------------------------------
    %
    %  Fitted Parameters:
    %    * fr :     fraction of water in the restricted compartment
    %    * Dh :    Apparent diffusion coefficient of the hindered compartment
    %
    %    * fcsf :  fraction of water in the CSF compartment. (fixed to 0 by default)
    %    * lc :   length of coherence. if >0, this parameter models the time dependence of the hindered
    %             diffusion coefficient Dh. Els Fieremans et al. Neuroimage 2016.
    %             Interpretation is not perfectly known. Use
    %             option "Time-Dependent Models" to get different interpretations.
    %
    %
    %  Non-Fitted Parameters:
    %    * fr = 1 - fh - fcsf : fraction of water in the restricted compartment (intra-axonal)
    %    * residue : Fitting residue.
    %
    %
    % Options:
    %   FILL
    %
    %
    % ----------------------------------------------------------------------------------------------------
    % Written by: Ian Gagnon, 2017
    % Reference: FILL
    % ----------------------------------------------------------------------------------------------------
    
    properties
        MRIinputs = {'MTdata','R1map','B1map','B0map','Mask'}; % input data required
        xnames = {'F','kr','R1f','R1r','T2f','T2r'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [ 0.16    10      1        1       0.03     1.3e-05 ]; % starting point
        lb           = [ 0       0       0.05     0.05    0        0       ]; % lower bound
        ub           = [ 0.5     30      5        5       0.5      5.0e-05 ]; % upper bound
        fx           = [ 0       0       1        1       0        0       ]; % fix parameters
        
        % Protocol
        % You can define a default protocol here.
        Prot = struct('MTdata',...
            struct('Format',{{'Angle' 'Offset'}},...
            'Mat', [142 443; 426 443; 142 1088; 426 1088; 142 2732
            426 2732; 142 6862; 426 6862; 142 17235; 426 17235]),...
            'TimingTable',...
            struct('Format',{{'Tmt (s)'; 'Ts (s)'; 'Tp (s)'; 'Tr (s)'; 'TR (s)'}},...
            'Mat',[0.0102; 0.0030; 0.0018; 0.0100; 0.0250]));
        
        ProtSfTable = struct; % SfTable declaration
        
        % Model options
        buttons = {'PANEL','MT_Pulse',5,...
            'Shape',{'gausshann','gaussian','hard','sinc','sinchann','sincgauss','fermi'},...
            'Sinc TBW', nan,...
            'Gaussian bandwidth',200,...
            'Fermi transition (a)', nan,...
            '# of MT pulses',100,...
            'Model',{'SledPikeRP','SledPikeCW','Yarnykh','Ramani'},...
            'Lineshape',{'SuperLorentzian','Lorentzian','Gaussian'},...
            'Use R1map to constrain R1f',true,...
            'Fix R1r = R1f',false,...
            'Read pulse alpha',7,...
            'PANEL','SfTable',2,...
            'Good',0,...
            'Compute',false};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
        % Simulations Default options
        Sim_Single_Voxel_Curve_buttons = {'SNR',50,'Method',{'Analytical equation','Block equation'},'Reset Mz',false};
        Sim_Sensitivity_Analysis_buttons = {'# of run',5};
    end
    
    methods
        function obj = SPGR_modulaire
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
            % Verification that the SfTable matches the current protocol
            SPGRDir = getSPGRDir();
            SfTablePath = [SPGRDir filesep 'SfTable.mat'];
            LastProt = loadStruct(SfTablePath,'LastProt'); 
            CurrentProt = GetProt(obj); 
            if isequal(CurrentProt,LastProt)
                obj.ProtSfTable = loadStruct(SfTablePath,'SfTable'); % SfTable associated with last protocol used
                obj.options.SfTable_Good = 'YES';
                obj.options.SfTable_Compute = false;
            else
                obj.options.SfTable_Good = 'NO';
                if obj.options.SfTable_Compute
                    obj.ProtSfTable = CacheSf(CurrentProt);
                    % Construct a questdlg with three options
                    choice = questdlg('Save this SfTable as default?', ...
                        'Save', ...
                        'Yes','No','Yes');
                    % Handle response
                    switch choice
                        case 'Yes'
                            SfTable = obj.ProtSfTable;
                            LastProt = CurrentProt;    
                            save(SfTablePath,'SfTable','LastProt');
                        case 'No'       
                    end
                    obj.options.SfTable_Compute = false;
                    obj.options.SfTable_Good = 'YES';
                end
            end
            % TR must be the sum of Tm, Ts, Tp and Tr
            obj.Prot.TimingTable.Mat(5) = obj.Prot.TimingTable.Mat(1)+...
                                          obj.Prot.TimingTable.Mat(2)+...
                                          obj.Prot.TimingTable.Mat(3)+...
                                          obj.Prot.TimingTable.Mat(4); 
            % Fix R1f if the option is chosen
            if obj.options.UseR1maptoconstrainR1f
                obj.fx(3)=true;
            end
        end
        
        function mz = equation(obj, x, Opt)
            for ix = 1:length(x)
                Sim.Param.(obj.xnames{ix}) = x(ix);
            end
            Protocol = GetProt(obj);
            switch Opt.Method
                case 'Block equation'
                    Sim.Param.lineshape = obj.options.Lineshape;
                    Sim.Param.M0f = 1;
                    Sim.Opt.Reset = Opt.ResetMz;
                    Sim.Opt.SScheck = 1;
                    Sim.Opt.SStol = 1e-4;
                    mz = SPGR_sim(Sim, Protocol, 1);
                case 'Analytical equation'
                    SimCurveResults = SPGR_SimCurve(Sim.Param, Protocol, obj.GetFitOpt, 1);
                    mz = SimCurveResults.curve;
            end
        end
        
        function FitResults = fit(obj,data)
            Protocol = GetProt(obj);
            FitOpt = GetFitOpt(obj,data);
            FitResults = SPGR_fit(data.MTdata,Protocol,FitOpt);
        end
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            % Example: obj.Sim_Single_Voxel_Curve(obj.st,button2opts(obj.Sim_Single_Voxel_Curve_buttons))
            if ~exist('display','var'), display = 1; end      
            Smodel = equation(obj, x, Opt);
            sigma = max(Smodel)/Opt.SNR;
            data.MTdata = random('rician',Smodel,sigma);
            FitResults = fit(obj,data);
            if display
                plotmodel(obj, FitResults, data);
            end
        end
        
        function SimVaryResults = Sim_Sensitivity_Analysis(obj, OptTable, Opts)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, Opts.Nofrun, OptTable, Opts);
        end

        function plotmodel(obj, x, data)
            Protocol = GetProt(obj);
            FitOpt = GetFitOpt(obj,data);
            SimCurveResults = SPGR_SimCurve(x, Protocol, FitOpt );
            Sim.Opt.AddNoise = 0;
            SPGR_PlotSimCurve(data.MTdata, data.MTdata, Protocol, Sim, SimCurveResults);
            title(sprintf('F=%0.2f; kf=%0.2f; R1f=%0.2f; R1r=%0.2f; T2f=%0.2f; T2r=%f; Residuals=%f', ...
                x.F,x.kf,x.R1f,x.R1r,x.T2f,x.T2r),...
                'FontSize',10);
        end
        
        %         function plotProt(obj)
        %             subplot(1,1,2)
        %             plot(obj.Prot.MTdata(:,1),obj.Prot.MTdata(:,2))
        %             subplot(2,1,2)
        %             title('MTpulse')
        %             angles = Prot.Angles(1);
        %             offsets = Prot.Offsets(1);
        %             shape = Prot.MTpulse.shape;
        %             Trf = Prot.Tm;
        %             PulseOpt = Prot.MTpulse.opt;
        %             Pulse = GetPulse(angles, offsets, Trf, shape, PulseOpt);
        %             figure();
        %             ViewPulse(Pulse,'b1');
        %         end
        %
        function Prot = GetProt(obj)
            Prot.Angles = obj.Prot.MTdata.Mat(:,1);
            Prot.Offsets = obj.Prot.MTdata.Mat(:,2);
            Prot.Alpha = obj.options.Readpulsealpha;
            Prot.MTpulse.shape = obj.options.MT_Pulse_Shape;
           	Prot.MTpulse.Npulse = obj.options.MT_Pulse_NofMTpulses;    
            Prot.Tm = obj.Prot.TimingTable.Mat(1);
            Prot.Ts = obj.Prot.TimingTable.Mat(2);
            Prot.Tp = obj.Prot.TimingTable.Mat(3);
            Prot.Tr = obj.Prot.TimingTable.Mat(4);
            Prot.TR = obj.Prot.TimingTable.Mat(5);
        end
        
        function FitOpt = GetFitOpt(obj,data)
            if exist('data','var')
                if isfield(data,'R1map'), FitOpt.R1 = data.R1map; end
                if isfield(data,'B1map'), FitOpt.B1 = data.B1map; end
                if isfield(data,'B0map'), FitOpt.B0 = data.B0map; end
            end
            FitOpt.R1map = obj.options.UseR1maptoconstrainR1f;
            FitOpt.fx = obj.fx;
            FitOpt.st = obj.st;
            FitOpt.lb = obj.lb;
            FitOpt.ub = obj.ub;
            FitOpt.names = obj.xnames;
            FitOpt.lineshape = obj.options.Lineshape;
            % Check is the Sf table had already been compute
            if ~isempty(obj.ProtSfTable);
                FitOpt.Sf = obj.ProtSfTable;
            end
            FitOpt.R1reqR1f = obj.options.FixR1rR1f;
            FitOpt.model = obj.options.Model;
        end
    end
end

function SPGRDir = getSPGRDir()
    fctPath = fileparts(which(mfilename()));
    qMRLabDir = fctPath(1:strfind(fctPath,'qMRLab')+6);
    SPGRDir = [qMRLabDir 'Data' filesep 'SPGR_demo'];
end

function struct = loadStruct(fullPathName,structName)
    tmp = load(fullPathName);
    struct = tmp.(structName);
end