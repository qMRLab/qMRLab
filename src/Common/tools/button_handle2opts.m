function opts = button_handle2opts(optsHandles)
% Read buttons values generated using GenerateButtons or qmrlab.gui.OptionsRenderer
% opts = button_handle2opts(optsHandles)
%
% DISPATCH IS ON CLASS, NOT ON 'Style'
%
% The legacy path switched on get(h,'Style'). That is unusable against native
% components and fails in two different ways, both measured on R2026b:
%
%   * checkbox / editfield / button / label -> get(h,'Style') THROWS
%     MATLAB:hg:InvalidProperty.
%   * dropdown / uitable -> it silently returns a 0x3 TABLE, the uistyle style
%     table, so a switch on it takes no branch and the option is dropped without
%     any error at all.
%
% The second is the dangerous one: an options struct quietly missing a field.
%
% CLASSES ARE PRESERVED DELIBERATELY
%
% A legacy checkbox returned get(h,'Value') as a DOUBLE; a native uicheckbox
% returns a LOGICAL. Left alone that changes the class of 21 options across 7
% models, and Model.options is written into saved FitResults -- so a fit saved
% after this change would differ in type from one saved before it, for no reason
% a user could see. double() holds the old contract.
%
% See also GenerateButtons, parseButtons, qmrlab.gui.OptionsRenderer

ff = fieldnames(optsHandles);
opts = struct();

for ii = 1:length(ff)
    h = optsHandles.(ff{ii});
    if ~isscalar(h) || ~isvalid(h); continue; end

    switch class(h)
        % ---- native components (qmrlab.gui.OptionsRenderer)
        case 'matlab.ui.control.CheckBox'
            opts.(ff{ii}) = double(h.Value);          % was a double under uicontrol

        case 'matlab.ui.control.StateButton'
            opts.(ff{ii}) = double(h.Value);
            h.Value = false;                          % momentary, as the legacy one was

        case 'matlab.ui.control.NumericEditField'
            opts.(ff{ii}) = h.Value;

        case 'matlab.ui.control.EditField'
            opts.(ff{ii}) = str2num(h.Value); %#ok<ST2NM>

        case 'matlab.ui.control.DropDown'
            opts.(ff{ii}) = h.Value;

        case 'matlab.ui.control.Table'
            opts.(ff{ii}) = h.Data;

        case 'matlab.ui.control.Label'
            % The generator returns a '<tag>lbl' companion for every labelled
            % control. Legacy labels fell through the Style switch silently; a
            % native one would throw, so skip them explicitly.
            continue

        % ---- legacy uicontrol, still produced by GenerateButtonsWithPanels for
        %      the three Sim add-on windows until Stage F retires them
        otherwise
            if strcmp(get(h, 'type'), 'uitable')
                opts.(ff{ii}) = get(h, 'Data');
            else
                switch get(h, 'Style')
                    case 'edit'
                        opts.(ff{ii}) = str2num(get(h, 'String')); %#ok<ST2NM>
                    case 'checkbox'
                        opts.(ff{ii}) = get(h, 'Value');
                    case 'popupmenu'
                        list = get(h, 'String');
                        opts.(ff{ii}) = list{get(h, 'Value')};
                    case 'togglebutton'
                        opts.(ff{ii}) = get(h, 'Value');
                        set(h, 'Value', 0);
                end
            end
    end
end
