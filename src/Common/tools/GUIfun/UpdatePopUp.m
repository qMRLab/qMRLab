function UpdatePopUp(handles)
Data   =  handles.CurrentData;
if length(Data.fields)>1
    Data.fields(strcmp(Data.fields,'Mask'))=[];
end
fields =  Data.fields;

setPopUp(handles.SourcePop, fields);
dim = size(Data.(fields{1})); if length(dim)<3, dim(3)=1; end
if dim(3)==1
    setPopUp(handles.ViewPop,'Axial');
    handles.tool.setviewplane(3);
elseif dim(2)==1
    setPopUp(handles.ViewPop,'Coronal');
    handles.tool.setviewplane(2);
elseif dim(1)==1
    setPopUp(handles.ViewPop,'Sagittal');
    handles.tool.setviewplane(1);
else
    setPopUp(handles.ViewPop,{'Axial','Coronal','Sagittal'});
end
UpdateSlice(handles)
guidata(findobj('Name','qMRLab'), handles);