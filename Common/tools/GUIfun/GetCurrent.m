function Current = GetCurrent(handles)
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
View = get(handles.ViewPop,'String'); if ~iscell(View), View = {View}; end
Slice = str2double(get(handles.SliceValue,'String'));
Time = str2double(get(handles.TimeValue,'String'));

Data = handles.CurrentData;
data = Data.(Source);
switch View{get(handles.ViewPop,'Value')}
    case 'Axial';  Current = squeeze(data(:,:,Slice,Time));
    case 'Coronal';  Current = squeeze(data(:,Slice,:,Time));
    case 'Sagittal';  Current = squeeze(data(Slice,:,:,Time));
end
