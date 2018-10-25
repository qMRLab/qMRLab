function DrawPlot(handles)
set(handles.SourcePop, 'Value',  1);
set(handles.ViewPop,   'Value',  1);
UpdatePopUp(handles);
GetPlotRange(handles);
Current = GetCurrent(handles);
% imagesc(flipdim(Current',1));
if isfield(handles,'tool')
handles.tool.setImage(Current)
else
    handles.tool = imtool3D(Current,[0.18 0 .78 1],handles.FitResultsPlotPanel);
end
guidata(findobj('Name','qMRLab'), handles);