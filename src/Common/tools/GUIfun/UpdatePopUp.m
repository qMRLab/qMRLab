function UpdatePopUp(handles)
Data   =  handles.CurrentData;
if length(Data.fields)>1
    Data.fields(strcmp(Data.fields,'Mask'))=[];
end
fields =  Data.fields;

set(handles.SourcePop, 'String', fields);
dim = size(Data.(fields{1})); if length(dim)<3, dim(3)=1; end
if dim(3)==1
    set(handles.ViewPop,'String','Axial');
    set(handles.ViewPop,'Value',1)
    handles.tool.setviewplane(3);
elseif dim(2)==1
    set(handles.ViewPop,'String','Coronal');
    set(handles.ViewPop,'Value',1)
    handles.tool.setviewplane(2);
elseif dim(1)==1
    set(handles.ViewPop,'String','Sagittal');
    set(handles.ViewPop,'Value',1)
    handles.tool.setviewplane(1);
else
    set(handles.ViewPop,'String',{'Axial','Coronal','Sagittal'});
end
UpdateSlice(handles)
guidata(findobj('Name','qMRLab'), handles);