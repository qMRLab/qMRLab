function Model = qMRpatch(Model,Mversion)
% Create new Model
Mname = class(Model);
Mversion = Mversion(1)*100+Mversion(2)*10+Mversion(2);
currversion = qMRLabVer;
currversion = currversion(1)*100+currversion(2)*10+currversion(2);
if Mversion < currversion
% SPGR
switch Mname
    case 'SPGR'
        if Mversion < 205 && currversion > 205
        end
end

elseif Mversion > currversion
    warning(['This Model file was generated using a newer qMRLab ' (num2str(Mversion))])
end