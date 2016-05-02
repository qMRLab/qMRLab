function LoadDefaultOptions(PathName)
%Load Default Options and setappdata
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% ----------------------------------------------------------------------------------------------------


Sim    =  load(fullfile(PathName, 'DefaultSim.mat'));
Prot   =  load(fullfile(PathName, 'DefaultProt.mat'));
FitOpt =  load(fullfile(PathName, 'DefaultFitOpt.mat'));

setappdata(0, 'Sim',    Sim);
setappdata(0, 'Prot',   Prot);
setappdata(0, 'FitOpt' ,FitOpt);


end
