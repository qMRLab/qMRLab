function UpdateSlice(app)
% UpdateSlice: set the compass letters for the current view plane.

% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Fran?ois Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :

% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------
%
% Stage F1: takes the app rather than a `handles` struct. The four compass
% labels are uilabels, whose text property is Text -- uilabel has no String at
% all, and the GUIDE-era set(...,'String',..) only worked because the migration
% adapter translated it.
%
% app.ViewPop.Value is an INDEX (see setPopUp), so the name is looked up in
% Items. Switching on the Value directly would silently match no case and leave
% all four letters stale.

View = app.ViewPop.Items;
if isempty(View); return; end
switch View{app.ViewPop.Value}
    case 'Axial'
        app.txt_OrientL.Text = 'L';
        app.txt_OrientR.Text = 'R';
        app.txt_OrientS.Text = 'A';
        app.txt_OrientI.Text = 'P';
    case 'Coronal'
        app.txt_OrientL.Text = 'L';
        app.txt_OrientR.Text = 'R';
        app.txt_OrientS.Text = 'S';
        app.txt_OrientI.Text = 'I';
    case 'Sagittal'
        app.txt_OrientL.Text = 'P';
        app.txt_OrientR.Text = 'A';
        app.txt_OrientS.Text = 'S';
        app.txt_OrientI.Text = 'I';
end
