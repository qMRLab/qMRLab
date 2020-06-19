classdef b1_afi < AbstractModel
% b1_afi map:  Actual Flip-Angle Imaging for B1+ mapping
%
% Assumptions:
%   
%
% Inputs:
%   AFIData1     3D Actual Flip Imaging (AFI) data 1
%   AFIData2     3D Actual Flip Imaging (AFI) data 2
%  (Mask)    Binary mask to exclude non-brain voxels
%
% Outputs:
%   B1map_afi    Actual/Nominal FA map
%
% Protocol:
%   Sequence    [nomFA; TR1; TR2]  nominal Flip Angle [deg]; TR1 [s]; TR2 [s]
%
% Options:
%   Parallelize: Parallelize the voxelwise computation
%     Multi CPU cores (only)
%
%
%
% Example of command line usage:
%   Model = b1_afi;  % Create class from model
%   Model.Prot.Sequence.Mat = txt2mat('seq.txt');  % Load protocol
%   data = struct;  % Create data structure
%   data.AFIData1 = load_nii_data('img1.nii.gz');
%   data.AFIData2 = load_nii_data('img2.nii.gz');
%   FitResults = FitData(data,Model); %fit data
%   FitResultsSave_nii(FitResults,'img1.nii.gz'); % Save in local folder: FitResults/
%
%   For more examples: <a href="matlab: qMRusage(b1_afi);">qMRusage(b1_afi)</a>
%
% Author: 
%
% References:
%   Please cite the following if you use this module:
%     Yarnykh, VL., 2007. Actual Flip-Angle Imaging in the Pulsed Steady State: A Method for Rapid Three Dimensional Mapping of the Transmitted Radiofrequency Field. Magn. Reson. Med. 57, 192?200.
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357


    properties (Hidden=true)
        onlineData_url = 'https://osf.io/csjgx/'; %Please check this link. I think the version is needed for it to work
    end

    properties
        MRIinputs = {'AFIData1','AFIData2', 'Mask'};
        xnames = {};
        voxelwise = 1;

        % Protocol
        Prot  = struct('Sequence',struct('Format',{{'nomFA';'TR1';'TR2'}},...
            'Mat',[60;20;100]));

        % Model options
        buttons = {'Parallelize',false};
        options= struct();

    end

    methods
        function obj = b1_afi
            obj.options = button2opts(obj.buttons);
        end

        function FitResults = fit(obj,data)
            nomFA = obj.Prot.Sequence.Mat(1); %nominal Flip Angle
            n = obj.Prot.Sequence.Mat(3)/obj.Prot.Sequence.Mat(2); %TR2/TR1
            if obj.options.Parallelize
                %Parallelization
                
                %1.- Distributed arrays
                %https://la.mathworks.com/help/parallel-computing/distributed-arrays.html
                img1 = distributed(data.AFIData1);
                img2 = distributed(data.AFIData2);
                r = abs(img2./img1); %Signal AFI2/Signal AFI1
                r = distributed(r);
                cos_arg = (r*n-1)./(n-r);
                cos_arg = distributed(cos_arg);
                cos_arg = double(cos_arg).*(r<=1) + ones(size(r)).*(r>1);
                AFImap = acos(cos_arg); %AFImap is in radians
                AFImap = AFImap*180/pi;
                AFImap = gather(AFImap);
                FitResults.B1map_afi = AFImap/nomFA;

%                 %2.- Submitting batch job
%                 %https://la.mathworks.com/help/parallel-computing/simple-batch-processing.html
%                 clust = parcluster('local');
%                 N = 4; %for a quad core computer
%                 %N = clust.NumIdleWorkers; %utilize all available workers
%                 img1 = data.AFIData1;
%                 img2 = data.AFIData2;
%                 job = batch(clust,@Parallelization,1,{n,img1,img2},'Pool',N-1);
%                 %get(job,'State');
%                 wait(job,'finished');
%                 
%                 %Retrieve results
%                 results = fetchOutputs(job);
%                 AFImap = results{1};
%                 delete(job);
%                 FitResults.B1map_afi = AFImap/nomFA;
            else
                r = abs(data.AFIData2./data.AFIData1); %Signal AFI2/Signal AFI1
                cos_arg = (r*n-1)./(n-r);
                % filter out cases where r > 1:
                % r should not be greater than one, so must be noise
                cos_arg = double(cos_arg).*(r<=1) + ones(size(r)).*(r>1);
                AFImap = acos(cos_arg); %AFImap is in radians
                AFImap = AFImap*180/pi;
                FitResults.B1map_afi = AFImap/nomFA;
            end
        end
        
        %This is the function I tried to use (nested in fit, locally and anonymous) for the Parallelize option
        function AFImap = Parallelization(n,img1,img2)
            r = abs(img2./img1); %Signal AFI2/Signal AFI1
            cos_arg = (r*n-1)./(n-r);
            cos_arg = double(cos_arg).*(r<=1) + ones(size(r)).*(r>1);
            AFImap = acos(cos_arg); %AFImap is in radians
            AFImap = AFImap*180/pi;
        end

    end

end