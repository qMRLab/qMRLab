function LoadDefaultOptions(PathName)
%Load Default Options and setappdata
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% ----------------------------------------------------------------------------------------------------

Simf=fullfile(PathName, 'DefaultSim.mat');
if exist(Simf,'file'), Sim    =  load(Simf); setappdata(0, 'Sim',    Sim); end
Protf   =  fullfile(PathName, 'DefaultProt.mat');
if exist(Protf,'file'), Prot    =  load(Protf); setappdata(0, 'Prot',    Prot); end
FitOptf =  fullfile(PathName, 'DefaultFitOpt.mat');
if exist(FitOptf,'file'), FitOpt    =  load(FitOptf); setappdata(0, 'FitOpt',    FitOpt); end

end
