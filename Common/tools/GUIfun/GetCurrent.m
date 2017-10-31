function Current = GetCurrent(handles)
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
View = get(handles.ViewPop,'Value');
Slice = str2double(get(handles.SliceValue,'String'));
Time = str2double(get(handles.TimeValue,'String'));

Data = handles.CurrentData;
data = Data.(Source);
switch View
    case 1;  Current = squeeze(data(:,:,Slice,Time));
    case 2;  Current = squeeze(data(:,Slice,:,Time));
    case 3;  Current = squeeze(data(Slice,:,:,Time));
end
