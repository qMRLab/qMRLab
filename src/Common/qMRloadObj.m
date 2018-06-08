function Model = qMRloadObj(filename)
if ~isstruct(filename) % load directly structure
    S = load(filename);
else
    S=filename;
end
Model = str2func(S.ModelName); 
Model = Model();
Model = Model.loadObj(filename);