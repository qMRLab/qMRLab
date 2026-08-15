function setPopUp(h, items, value)
%setPopUp  Assign a dropdown's list and its selection, keeping Value an INDEX.
%
%   setPopUp(h, items)         install the list, select the first entry
%   setPopUp(h, items, value)  install the list, select index value (clamped)
%
%   h is a matlab.ui.control.DropDown. value is a 1-BASED INDEX, and after this
%   call h.Value is that index -- a number, not the item's text.
%
%   WHY Value IS AN INDEX, WHICH IS NOT THE NATIVE DEFAULT
%
%   A bare uidropdown's Value is the SELECTED ITEM'S TEXT. Measured on R2026b:
%
%       no ItemsData : Value='A'  class=char
%       ItemsData 1:N: Value=1    class=double
%
%   The index is the contract this codebase needs, in four places that have no
%   text-accepting form: GetMethod indexes MethodList, imtool3D.setNvol needs an
%   integer volume number, UpdateSlice switches on the view name it looks up, and
%   DrawPlot passes tool.getNvol straight back in. Worse, MethodSelection's Items
%   are PADDED display strings ('inversion_recovery   (T1_relaxometry/)'), so a
%   text Value would have to be parsed back into a class name -- and "Set as
%   default" writes that value into DefaultMethod.mat, where a padded string
%   poisons the next launch.
%
%   So ItemsData carries 1:numel(Items) and Value stays an index. ItemsData is
%   R2016a, well below the R2020b floor in ADR D5.
%
%   ORDER MATTERS, AND IT IS THE OPPOSITE OF WHAT IT WAS
%
%   The GUIDE-era body was "neutralise, install, select" -- set(h,'Value',1)
%   BEFORE the list. Natively that throws: an empty-Items dropdown requires an
%   empty Value, and app.SourcePop is constructed with Items={}, so the very
%   first call from UpdatePopUp would die before installing anything.
%
%   Items go first; the component recalibrates its own selection. ItemsData is
%   then reassigned on EVERY call, because the component enforces
%   maxValidIndex = min(numel(Items), numel(ItemsData)) -- a stale ItemsData
%   silently caps the list. Measured: with Items shrunk to 1 entry and a stale
%   3-element ItemsData left in place, no error is raised and the dropdown is
%   left inconsistent (1 item, 3 ItemsData entries).
%
%   The old header documented an ordering hazard where a stale Value index made
%   the NEXT list assignment throw MATLAB:badsubscript. That was an artefact of
%   the migration adapter re-deriving value=str{value}; it does not exist
%   natively, and the adapter is gone.
%
%   See also: DrawPlot, UpdatePopUp, GetMethod

    if nargin < 3 || isempty(value) || ~isnumeric(value); value = 1; end

    if isempty(items)
        items = {};
    elseif ~iscell(items)
        items = cellstr(items);
    end
    items = reshape(items, 1, []);

    h.Items = items;
    if isempty(items)
        h.ItemsData = [];
    else
        h.ItemsData = 1:numel(items);
        h.Value     = min(max(round(value(1)), 1), numel(items));
    end
end
