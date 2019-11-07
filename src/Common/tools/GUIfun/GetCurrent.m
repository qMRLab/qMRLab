function [Current, CurrentMask]= GetCurrent(handles)
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
View = get(handles.ViewPop,'String'); if ~iscell(View), View = {View}; end
View = View{get(handles.ViewPop,'Value')};

Data = handles.CurrentData;
data = Data.(Source);
Current = ApplyView(data, View);

if isfield(Data,'Mask')
    Mask = Data.Mask;
    CurrentMask = ApplyView(Mask, View);
else
    CurrentMask = [];
end