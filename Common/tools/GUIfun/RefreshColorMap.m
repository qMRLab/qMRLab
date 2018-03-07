function RefreshColorMap(handles)
val  = get(handles.ColorMapStyle, 'Value');
maps = get(handles.ColorMapStyle, 'String'); 
colormap(maps{val});
colorbar('Location', 'EastOutside', 'AxisLocation', 'in', 'Color', 'black', 'LineWidth', 1.5, 'FontSize', 14);
min = str2double(get(handles.MinValue, 'String'));
max = str2double(get(handles.MaxValue, 'String'));
caxis([min max]);