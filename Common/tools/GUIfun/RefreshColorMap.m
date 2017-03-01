function RefreshColorMap(handles)
val  = get(handles.ColorMapStyle, 'Value');
maps = get(handles.ColorMapStyle, 'String'); 
colormap(maps{val});
colorbar('location', 'South', 'Color', 'white');
min = str2double(get(handles.MinValue, 'String'));
max = str2double(get(handles.MaxValue, 'String'));
caxis([min max]);