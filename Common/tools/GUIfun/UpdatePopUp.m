function UpdatePopUp(handles)
axes(handles.FitDataAxe);
Data   =  handles.CurrentData;
fields =  Data.fields;
set(handles.SourcePop, 'String', fields);
handles.FitDataSize = size(Data.(fields{1}));
handles.FitDataDim = size(Data.(fields{1})); if length(handles.FitDataDim)<3, handles.FitDataDim(3)=1; end
dim = handles.FitDataDim;
if dim(3)>1
        set(handles.ViewPop,'String',{'Axial','Coronal','Sagittal'});
        handles.FitDataSlice = floor(handles.FitDataSize/2);
else
        set(handles.ViewPop,'String','Axial');
        handles.FitDataSlice = 1;
end
UpdateSlice(handles)
guidata(gcbf, handles);