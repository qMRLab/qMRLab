function Model = qMRloadObj(filename)
% loads a qMR Model file
%
% qMRloadObj(filename)
% filename: file path with extension ".qmrlab.mat"

if ~isstruct(filename) % load directly structure
    S = load(filename);
else
    S=filename;
end
Model = str2func(S.ModelName); 
Model = Model();
Model = Model.loadObj(filename);