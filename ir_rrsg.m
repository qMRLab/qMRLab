function ir_rrsg(inputFilename, outputFilename)

load(inputFilename)

% Assign data to variables needed for qMRLab module
IRData = data;

if exist('mask')
  Mask = mask;
end

% Format qMRLab inversion_recovery model parameters, and load them into the Model object
Model = inversion_recovery; 

% Set the customizable settings in the model
Model.Prot.IRData.Mat = [TI'];
Model.options.method = dataType;

% Format data structure so that they may be fit by the model
data = struct();
data.IRData= double(IRData);

if exist('mask')
  data.Mask= double(Mask);
end

FitResults = FitData(data,Model,0); % The '0' flag is so that no wait bar is shown.

save(outputFilename, 'FitResults')

end
