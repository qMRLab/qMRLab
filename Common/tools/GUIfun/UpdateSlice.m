function UpdateSlice(handles)
% UpdateSlice

% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :

% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------

View =  get(handles.ViewPop,'Value');
switch View
    case 1
        x = 3;
    case 2
        x = 2;
    case 3
        x = 1;
end
dim = handles.FitDataDim;
if (dim>=3)
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