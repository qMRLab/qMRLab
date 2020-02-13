function ir_rrsg(varargin)

% varargin 1 is reserved for $LD_LIBRARY_PATH
    
disp(['Received file input: ' varargin{2}]);

inputFilename = varargin{2};
outputFilename = varargin{3};

inps = load(inputFilename);

% Format qMRLab inversion_recovery model parameters, and load them into the Model object
Model = inversion_recovery; 

% Format data structure so that they may be fit by the model
data = struct();
data.IRData= double(inps.data);

if isfield(inps,'mask')
    data.Mask= double(inps.mask);
end

% Set the customizable settings in the model
Model.Prot.IRData.Mat = inps.TI';
Model.options.method = inps.dataType;

FitResults = FitData(data,Model,0); % The '0' flag is so that no wait bar is shown.

save(outputFilename, 'FitResults')

end