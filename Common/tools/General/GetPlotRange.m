function GetPlotRange(handles)
Current = GetCurrent(handles);
values=Current(:); values(isinf(values))=[]; values(isnan(values))=[];

% special for MTSAT - keep negative values - do not take percentile of SI
%set(handles.MethodMenu, 'Value', ii);
Method = GetMethod(handles);

if strcmp(Method, 'MTSAT')
    Min = min(min(values));
    Max = max(max(values));
    
    set(handles.MinValue, 'Min', Min);
    set(handles.MinValue, 'Max', Max);
    set(handles.MinValue, 'String', Min);
    set(handles.MinValue, 'Value', Min);
    set(handles.MaxValue, 'Min', Min);
    set(handles.MaxValue, 'Max', Max);
    set(handles.MaxValue, 'String', Max);
    set(handles.MaxValue, 'Value', Max);
else   
    Min = prctile(values,5); % 5 percentile of the data to prevent extreme values
    Max = prctile(values,95);% 95 percentile of the data to prevent extreme values
    if (Min == Max)
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
end

guidata(gcbf, handles);
