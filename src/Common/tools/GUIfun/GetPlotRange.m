
function GetPlotRange(handles)
if isempty(handles.CurrentData), return; end
Current = GetCurrent(handles);
values=Current(:); values(isinf(values))=[]; values(isnan(values))=[]; 

if length(unique(values))>20 % it is a mask?
    values(~values)=[];
    [Min, Max] = range_outlier(values);
else
    Min=min(values);
    Max=max(values);
end

if (abs(Min - Max)<1e-3)
    Max = Max + 1;
end
if (Min > Max)
    temp = Min;
    Min = Max;
    Max = temp;
end

if (Min < 0)
    set(handles.MinSlider, 'Min',    1.5*Min);
else
    set(handles.MinSlider, 'Min',    0.5*Min);
end

if (Max < 0)
    set(handles.MaxSlider, 'Max',    0.5*Max);
else
    set(handles.MaxSlider, 'Max',    1.5*Max);
end
set(handles.MinSlider, 'Max',    Max);
set(handles.MaxSlider, 'Min',    Min);
set(handles.MinValue,  'String', Min);
set(handles.MaxValue,  'String', Max);
set(handles.MinSlider, 'Value',  Min);
set(handles.MaxSlider, 'Value',  Max);
guidata(findobj('Name','qMRLab'), handles);