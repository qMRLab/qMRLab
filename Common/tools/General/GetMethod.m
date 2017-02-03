% GET METHOD
function Method = GetMethod(handles)
contents =  cellstr(get(handles.MethodMenu, 'String'));
Method   =  contents{get(handles.MethodMenu, 'Value')};
setappdata(0, 'Method', Method);
handles.method = fullfile(handles.root, Method);
guidata(gcf,handles);
ClearAxes(handles);

        MethodsList = getappdata(0, 'MethodsListed');
        MethodsSize = size(MethodsList);
        NbMethods = MethodsSize(2);
        for i=1:NbMethods
            if MethodsList(i).IsMethod(Method) == 0
                MethodsList(i).Visible('on');
            else
                MethodsList(i).Visible('off');
            end
        end
        
        
switch Method
    case 'bSSFP'
        set(handles.SimCurveAxe1, 'Visible', 'on');
        set(handles.SimCurveAxe2, 'Visible', 'on');
        set(handles.SimCurveAxe,  'Visible', 'off');
    case 'MTSAT'
        %SetActive('MTSAT', handles);
        set(handles.SimCurveAxe1, 'Visible', 'off');
        set(handles.SimCurveAxe2, 'Visible', 'off');
        set(handles.SimCurveAxe,  'Visible', 'on');
    otherwise
        set(handles.SimCurveAxe1, 'Visible', 'off');
        set(handles.SimCurveAxe2, 'Visible', 'off');
        set(handles.SimCurveAxe,  'Visible', 'on');
end
