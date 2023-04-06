classdef b0_mem < AbstractModel
    
     properties
        MRIinputs = {'Phase','Magn'};
        xnames = {'B0 (Hz)'};
        voxelwise = 0; % 0, if the analysis is done matricially
                       % 1, if the analysis is done voxel per voxel

        % Protocol
        % You can define a default protocol fhere.
        Prot = struct('TimingTable',struct('Format',{{'deltaTE'}},'Mat', [1.92e-3; 2e-3]));

        % Model options
        buttons = {'Magn thresh',.05};
        options = struct(); % structure filled by the buttons. Leave empty in the code

    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods
        function obj = b0_mem
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end

        function obj = UpdateFields(obj)
            obj.options.Magnthresh = max(obj.options.Magnthresh,0);
        end

        function FitResult = fit(obj,data)
            Phase = data.Phase;
            Magn = data.Magn;

%             % FSL "prelude"
%             mkdir('tmp')
%             save_nii(make_nii(Phase),'tmp/Phase.nii');
%             save_nii(make_nii(Magn),'tmp/Magn.nii');
%             unix('prelude -p tmp/Phase.nii -a tmp/Magn.nii -o tmp/Ph_uw -f');
%             B0 = load_untouch_nii('tmp/Ph_uw.nii.gz');
%             rmdir('tmp','s')
%             B0.img = unwrap(B0.img,[],4);
%             FitResult.B0map = (B0.img(:,:,:,2) - B0.img(:,:,:,1))/(obj.Prot.TimingTable.Mat*2*pi);
  
            sizecheck = true;
            if not(length(size(Magn)) == length(size(Phase)))
                FitResult = "The size of the magnitude and phase don't match";
                sizecheck = false;
            else
                if not(size(Magn, 1:2) == size(Phase, 1:2))
                    FitResult = "The size of the magnitude and phase don't match";
                    sizecheck = false;
                end 
            end
            


            % phase in radians check ("ERROR MESSAGE")
            radcheck = true;
            for iEcho = 1:size(Phase,4)
                if max(Phase(:,:,:,iEcho), [], "all") > pi || min(Phase(:,:,:,iEcho), [], "all") < -pi
                    FitResult = "The data isn't in radians";
                    radcheck = false;
                end
            end

            % 2D or 3D data ?
            if any(size(Phase) == 1)
                TwoD  = true;
            else
                TwoD = false;
            end

            % Makes sure the number of echo times makes sense ("ERROR
            % MESSAGE")
            Techocheck = true;
            if length(obj.Prot.TimingTable.Mat)==1
                   Techo = 0:obj.Prot.TimingTable.Mat:size(Phase,4)*obj.Prot.TimingTable.Mat;
                else
                    if length(obj.Prot.TimingTable.Mat)== size(Phase,4)
                        Techo = obj.Prot.TimingTable.Mat;
                    else
                        Techocheck = false;
                    end
            end 

            if (radcheck == true && sizecheck == true && Techocheck == true)

                % MATLAB "sunwrap" for 2D data
                Phase_uw = Phase;
                if TwoD
                    Complex = Magn.*exp(Phase*1i);
                    for iEcho = 1:size(Magn,4)
                        Phase_uw(:,:,:,iEcho) = sunwrap(Complex(:,:,:,iEcho));
                    end
                % MATLAB "laplacianUnwrap" for 3D data
                else
                    for iEcho = 1:size(Phase,4)
                        Phase_uw(:,:,:,iEcho) = laplacianUnwrap(Phase(:,:,:,iEcho), Magn>obj.options.Magnthresh);
                    end
                end
                %obj.Prot.TimingTable.Mat
                Time = 0.001;
                Techo = zeros(1,size(Phase,4));
                for iEcho = 0:size(Phase,4)-1
                    Techo(iEcho+1) = Time*iEcho;
                end
                FitResult.B0map = zeros(size(Phase, 1:2));
                for i = 1:size(Phase, 1)
                    for j = 1:size(Phase,2)
                        Phase_vec= zeros(1,size(Phase,4));
                        for iEcho = 1:size(Phase,4)-1
                            Phase_vec(iEcho) = Phase_uw(i, j, :,iEcho);
                    FitResult.B0map(i, j) = polyfit(Techo, Phase_vec, 0)/(2*pi);
                        end 
                    end 
                end
                
            
                % Save unwrapped phase
                FitResult.Phase_uw = Phase_uw;
            end 
        end 
    end
end 
