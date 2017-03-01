function LoadDefaultOptions(PathName)
%Load Default Options and setappdata
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% ----------------------------------------------------------------------------------------------------

CompleteFileName = fullfile(PathName, 'DefaultSim.mat');
if exist(CompleteFileName)
    Sim    =  load(CompleteFileName);
else 
    errordlg('Missing DefaultSim.mat file in Parameters folder'); return;
end


CompleteFileName = fullfile(PathName, 'DefaultProt.mat');
if exist(CompleteFileName)
    Prot   =  load(CompleteFileName);
else 
    errordlg('Missing DefaultProt.mat file in Parameters folder'); return;
end

CompleteFileName = fullfile(PathName, 'DefaultFitOpt.mat');
if exist(CompleteFileName)
    FitOpt =  load(CompleteFileName);
else
    errordlg('Missing DefaultFitOpt.mat file in Parameters folder'); return;
end

setappdata(0, 'Sim',    Sim);
setappdata(0, 'Prot',   Prot);
setappdata(0, 'FitOpt' ,FitOpt);


end
