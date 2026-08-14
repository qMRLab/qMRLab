function setPopUp(h, items, value)
%setPopUp  Assign a popup's list and its selection in the one order that works.
%
%   setPopUp(h, items)         install the list, select the first entry
%   setPopUp(h, items, value)  install the list, select index value (clamped)
%
%   WHY THIS IS NOT JUST TWO set() CALLS
%
%   The migrated GUI reaches these dropdowns through the `handles` struct, and
%   MATLAB's migration runtime wraps every tagged component there in a
%   uicontrol-compatibility adapter (appdesigner.appmigration.UIControlPropertiesConverter).
%   That adapter validates an incoming legacy Value INDEX against the items the
%   dropdown holds AT THAT MOMENT. A selection left over from a previous, longer
%   list therefore makes the NEXT list assignment throw -- not the assignment that
%   set it. Measured on R2026b:
%
%       set(C,'Value',3)                          % Items empty  -> OK
%       set(C,'String',{'A'})                     %              -> THROW MATLAB:badsubscript
%
%       set(C,'String',{'A','B','C'}); set(C,'Value',3);
%       set(C,'String','Axial')                   % 3 is stale   -> THROW MATLAB:badsubscript
%
%   The failure is therefore displaced in both space and time: it surfaces in
%   whichever function next shrinks the list, and only on the SECOND dataset,
%   because the first load starts from an empty list where any index is accepted.
%   That is why it survived the migration unnoticed.
%
%   Neutralise, install, select. Safe from any starting state.
%
%   See also: DrawPlot, UpdatePopUp

    if nargin < 3 || isempty(value); value = 1; end

    if isempty(items)
        items = {};
    elseif ~iscell(items)
        items = cellstr(items);
    end

    % 1 is in range for any non-empty list, and accepted on an empty one.
    set(h, 'Value', 1);
    set(h, 'String', items);

    if ~isempty(items)
        set(h, 'Value', min(max(round(value(1)), 1), numel(items)));
    end
end
