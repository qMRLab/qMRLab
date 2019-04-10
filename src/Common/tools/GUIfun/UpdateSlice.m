function UpdateSlice(handles)
% UpdateSlice: set slice slider maximal value

% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Fran?ois Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :

% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------

View =  get(handles.ViewPop,'String'); if ~iscell(View), View = {View}; end
switch View{get(handles.ViewPop,'Value')}
    case 'Axial'
        set(handles.txt_OrientL,  'String', 'L');
        set(handles.txt_OrientR,  'String', 'R');
        set(handles.txt_OrientS,  'String', 'A');
        set(handles.txt_OrientI,  'String', 'P');
    case 'Coronal'
        set(handles.txt_OrientL,  'String', 'L');
        set(handles.txt_OrientR,  'String', 'R');
        set(handles.txt_OrientS,  'String', 'S');
        set(handles.txt_OrientI,  'String', 'I');
    case 'Sagittal'
        set(handles.txt_OrientL,  'String', 'P');
        set(handles.txt_OrientR,  'String', 'A');
        set(handles.txt_OrientS,  'String', 'S');
        set(handles.txt_OrientI,  'String', 'I');
end