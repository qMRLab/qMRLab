function DrawPlot(handles)
set(handles.SourcePop, 'Value',  1);
set(handles.ViewPop,   'Value',  1);
UpdatePopUp(handles);
GetPlotRange(handles);
Current = GetCurrent(handles);
% imagesc(flipdim(Current',1));
imagesc(rot90(Current));
axis equal off;
RefreshColorMap(handles)