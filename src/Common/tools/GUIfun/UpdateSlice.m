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
        x = 3;
        set(handles.txt_OrientL,  'String', 'L');
        set(handles.txt_OrientR,  'String', 'R');
        set(handles.txt_OrientS,  'String', 'A');
        set(handles.txt_OrientI,  'String', 'P');
    case 'Coronal'
        x = 2;
        set(handles.txt_OrientL,  'String', 'L');
        set(handles.txt_OrientR,  'String', 'R');
        set(handles.txt_OrientS,  'String', 'S');
        set(handles.txt_OrientI,  'String', 'I');
    case 'Sagittal'
        x = 1;
        set(handles.txt_OrientL,  'String', 'P');
        set(handles.txt_OrientR,  'String', 'A');
        set(handles.txt_OrientS,  'String', 'S');
        set(handles.txt_OrientI,  'String', 'I');
end
dim = handles.FitDataDim;
if (min(dim(1:3))>1)
    slice = handles.FitDataSlice(x);
    size = handles.FitDataSize(x);
    set(handles.SliceValue,  'String', slice);
    set(handles.SliceSlider, 'Min',    1);
    set(handles.SliceSlider, 'Max',    size);
    set(handles.SliceSlider, 'Value',  slice);
    Step = [1, 1] / size;
    set(handles.SliceSlider, 'SliderStep', Step);
else
    set(handles.SliceValue,  'String',1);
    set(handles.SliceSlider, 'Min',   0);
    set(handles.SliceSlider, 'Max',   1);
    set(handles.SliceSlider, 'Value', 1);
    set(handles.SliceSlider, 'SliderStep', [0 0]);
end

% Set Time (Vol #) slider max value
if length(dim)<4, dim(4)=1; end 
set(handles.TimeSlider,  'Max',dim(4));
set(handles.TimeSlider,  'SliderStep',[1, 1] / dim(4));
% if new Data has fewer volumes,set to maximal volume #
TimeBounded = min(dim(4),str2double(get(handles.TimeValue,'String')));
set(handles.TimeValue,'String',TimeBounded)
set(handles.TimeSlider,'Value',TimeBounded)