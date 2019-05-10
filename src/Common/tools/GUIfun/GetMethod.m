% GET METHOD
function Method = GetMethod(handles)
index = get(handles.MethodSelection,'Value');
MethodList = getappdata(0, 'MethodList');
Method = MethodList{index};