function Model = qMRloadObj(filename)
% qMRloadObj    Load a qMR Model file (.qmr file)
%
% Example
%   Model = qMRloadObj('mwf.qmr');
%   qMRusage(Model)
if nargin==0, help('qMRloadObj'); return; end
if ~isobject(filename)
    if ~isstruct(filename) % load directly structure
        S = load(filename);
    else
        S=filename;
    end
    Model = str2func(S.ModelName); 
    Model = Model();
    Model = Model.loadObj(filename);
else
    Model = filename;
end
