function Model = qMRpatch(Model,Mversion)
% Create new Model
Mname = class(Model);
Mversion = Mversion(1)*100+Mversion(2)*10+Mversion(3);
currversion = qMRLabVer;
currversion = currversion(1)*100+currversion(2)*10+currversion(3);
if Mversion < currversion
% SPGR
switch Mname
    case 'SPGR'
        if Mversion < 205 && currversion > 205
        end
    case 'B0_DEM'
        if Mversion <= 205 && currversion > 205
            Model= renamebutton(Model,'Magn thresh lb','Magn thresh');
        end
end

elseif Mversion > currversion
    warning(['This Model file was generated using a newer qMRLab ' (num2str(Mversion))])
end

end

function Model = renamebutton(Model,oldname,newname)
    Model.options.(genvarname_v2(newname)) = Model.options.(genvarname_v2(oldname));
    Model.options = rmfield(Model.options,genvarname_v2(oldname));
    Model.buttons{strcmp(Model.buttons,oldname)}=newname;
end