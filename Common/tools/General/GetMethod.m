% GET METHOD
function Method = GetMethod(handles)
contents =  cellstr(get(handles.MethodMenu, 'String'));
Method   =  contents{get(handles.MethodMenu, 'Value')};
setappdata(0, 'Method', Method);