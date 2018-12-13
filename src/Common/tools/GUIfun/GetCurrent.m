function Current = GetCurrent(handles)
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
View = get(handles.ViewPop,'String'); if ~iscell(View), View = {View}; end

Data = handles.CurrentData;
data = Data.(Source);

switch View{get(handles.ViewPop,'Value')}
    case 'Axial';  Current = permute(data,[1 2 3 4 5]);
    case 'Coronal';  Current = permute(data,[1 3 2 4 5]);
    case 'Sagittal';  Current = permute(data,[2 3 1 4 5]);
end