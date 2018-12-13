function UpdatePopUp(handles)
Data   =  handles.CurrentData;
fields =  Data.fields;
set(handles.SourcePop, 'String', fields);
handles.FitDataSize = size(Data.(fields{1}));
handles.FitDataDim = size(Data.(fields{1})); if length(handles.FitDataDim)<3, handles.FitDataDim(3)=1; end
dim = handles.FitDataDim;
if dim(3)==1
    set(handles.ViewPop,'String','Axial');
    handles.FitDataSlice = 1;
elseif dim(2)==1
    set(handles.ViewPop,'String','Coronal');
    handles.FitDataSlice = 1;
elseif dim(1)==1
    set(handles.ViewPop,'String','Sagittal');
    handles.FitDataSlice = 1;
else
    set(handles.ViewPop,'String',{'Axial','Coronal','Sagittal'});
    handles.FitDataSlice = max(1,floor(handles.FitDataSize/2));
end
UpdateSlice(handles)
guidata(findobj('Name','qMRLab'), handles);