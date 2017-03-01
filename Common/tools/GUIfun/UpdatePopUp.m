function UpdatePopUp(handles)
axes(handles.FitDataAxe);
Data   =  handles.CurrentData;
fields =  Data.fields;
set(handles.SourcePop, 'String', fields);
handles.FitDataSize = size(Data.(fields{1}));
handles.FitDataDim = ndims(Data.(fields{1}));
dim = handles.FitDataDim;
if (dim==3)
        set(handles.ViewPop,'String',{'Axial','Coronal','Sagittal'});
        handles.FitDataSlice = floor(handles.FitDataSize/2);
else
        set(handles.ViewPop,'String','Axial');
        handles.FitDataSlice = 1;
end
UpdateSlice(handles)
guidata(gcbf, handles);