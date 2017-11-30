function Model = qMRloadObj(filename)
S = load(filename);
Model = str2func(S.ModelName); Model = Model();
Model.loadObj(filename);