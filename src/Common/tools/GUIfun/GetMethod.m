% GET METHOD
function Method = GetMethod(handles)
index = get(handles.MethodSelection,'Value');
methods = sct_tools_ls([handles.ModelDir filesep '*.m'], 0,0,2,1);
Method = methods{index};