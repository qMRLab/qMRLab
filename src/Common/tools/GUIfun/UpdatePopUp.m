function UpdatePopUp(app)
% UpdatePopUp  Refill the Volume list from the current data, and pick a plane.
%
%   Stage F1: takes the app rather than a `handles` struct, and no longer
%   republishes into guidata. The old last line was
%
%       guidata(findobj('Name','qMRLab'), handles);
%
%   which wrote back a byte-identical copy -- this function mutates components
%   and the imtool3D handle, never the struct -- so it only ever moved the
%   commit point a few lines earlier than DrawPlot's own write-back. With the
%   state on the app there is nothing to commit.
%
%   setviewplane is given the NUMBER deliberately: imtool3D maps sagittal->1,
%   coronal->2, anything else->3 (imtool3D.m:1056-1065). These are not dropdown
%   indices and must not be replaced by app.ViewPop.Value -- for a
%   single-entry {'Coronal'} list that index is 1, which would select Sagittal.

Data = app.CurrentData;
if length(Data.fields)>1
    Data.fields(strcmp(Data.fields,'Mask'))=[];
end
fields =  Data.fields;

setPopUp(app.SourcePop, fields);
dim = size(Data.(fields{1})); if length(dim)<3, dim(3)=1; end
if dim(3)==1
    setPopUp(app.ViewPop,'Axial');
    app.Tool.setviewplane(3);
elseif dim(2)==1
    setPopUp(app.ViewPop,'Coronal');
    app.Tool.setviewplane(2);
elseif dim(1)==1
    setPopUp(app.ViewPop,'Sagittal');
    app.Tool.setviewplane(1);
else
    setPopUp(app.ViewPop,{'Axial','Coronal','Sagittal'});
end
UpdateSlice(app)
