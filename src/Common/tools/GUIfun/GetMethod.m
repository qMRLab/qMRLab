function Method = GetMethod(app)
% GET METHOD  The model class name currently selected in the main window.
%
%   Takes the app, not a `handles` struct (Stage F1). app.MethodSelection.Value
%   is a 1-based INDEX rather than the item's text -- see setPopUp for why the
%   dropdowns carry ItemsData -- and MethodList holds the bare class names that
%   the padded display strings in Items are built from.
%
%   NOTE: MainApp must never declare a method named GetMethod. The argument is
%   now an object, so a same-named method would silently win dispatch and this
%   file would stop being called. (MethodBrowser.m also defines a GetMethod; it
%   is an unrelated class method.)
index = app.MethodSelection.Value;
MethodList = getappdata(0, 'MethodList');
Method = MethodList{index};
