function d = parseButtons(buttons)
%parseButtons  The `buttons` DSL, parsed into descriptors. No graphics.
%
%   d = parseButtons(Model.buttons) returns a struct array, one element per
%   option, in declaration order, with fields:
%
%       Kind        'checkbox' | 'number' | 'list' | 'table' | 'button'
%       Label       what the control is labelled, prefixes stripped
%       Field       genvarname_v2 of the stripped label -- the BARE tag
%       Handle      the name GenerateButtonsWithPanels gives this control in its
%                   returned struct, AND the key it takes in Model.options:
%                   Field outside a panel, <PanelField>_<Field> inside one.
%                   Use Handle, not Field, to reach an option's value: a panelled
%                   option like qmt_spgr's lives at 'Riciannoisebias_Method',
%                   never at 'Method'.
%       Panel       the panel title, prefixes intact, or '' outside a panel
%       PanelField  genvarname_v2 of Panel, or ''
%       PanelHidden true when the panel title starts with '##'
%       Disabled    true when the label started with '##'   (the ### convention)
%       Hidden      true when the label started with '**'   (the *** convention)
%       Declared    the value as written in the buttons cell
%       Choices     the choice list, for 'list' only
%
%   WHY THIS EXISTS, AND WHY IT IS NOT A REFACTOR OF THE GENERATOR
%
%   GenerateButtonsWithPanels parses the DSL and builds widgets in one pass, so
%   the layout could not be replaced without also re-deriving the naming. This
%   splits the parse out, graphics-free, so the renderer is free to change while
%   the names -- which are `Model.options` field names, and therefore land in
%   saved FitResults -- stay bit-identical.
%
%   Pure and Octave-clean on purpose: no handles, no figures, no globals. It is
%   safe to call on the CLI path.
%
%   THE CONTRACT IS FROZEN, INCLUDING ITS BUGS
%
%   Two behaviours here look like mistakes and are load-bearing. Both are
%   reproduced deliberately; see docs/adr/0001-gui-migration.md.
%
%   1. The prefix strip takes TWO characters while the documented markers are
%      three. '###Rician noise bias' loses '##', leaving '#Rician noise bias',
%      and genvarname_v2 maps a surviving '#' to 'N' -- so the field is
%      'NRiciannoisebias'. Without the prefix it is 'Riciannoisebias'. Toggling
%      the prefix therefore RENAMES the option, which dti.m:135-137 does at
%      runtime from UpdateFields. "Fixing" it changes option field names and
%      silently invalidates saved FitResults.
%
%   2. The '**' test runs on the string left by the '##' test, so the two
%      prefixes do not compose in the order a reader expects.
%
%   Do NOT refactor button2opts.m to call this. It is on the Octave/CLI path;
%   keep them parallel and assert they agree (Test/GUI/tDSL.m).
%
%   See also: GenerateButtonsWithPanels, button2opts, genvarname_v2, button_handle2opts

    d = emptyDescriptor();
    if nargin < 1 || isempty(buttons); return; end

    % --- Lift the PANEL declarations out, exactly as the generator does.
    %
    % 'PANEL', title, count triples are removed from the list as they are found,
    % so each subsequent panel's index shifts back by 3 per panel already taken --
    % that is what the -3*(i-1) is for. The indices left in PanelNum are positions
    % in the CLEANED list.
    panelPos       = find(strcmp(buttons, 'PANEL'));
    nPanel         = numel(panelPos);
    nOpts          = numel(buttons) - 3*nPanel;
    panelNum       = ones(1, nPanel);
    panelTitle     = cell(1, nPanel);
    panelnElements = ones(1, nPanel);

    for i = 1:nPanel
        panelNum(i)       = panelPos(i) - 3*(i-1);
        panelTitle{i}     = buttons{panelNum(i)+1};
        panelnElements(i) = buttons{panelNum(i)+2};
        buttons(panelNum(i) + (0:2)) = [];
    end
    opts = buttons;

    % --- Which flat index belongs to which panel.
    panelOf = zeros(1, nOpts);          % 0 = not in a panel
    for iP = 1:nPanel
        first = panelNum(iP);
        last  = panelNum(iP) + 2*panelnElements(iP) - 1;
        panelOf(first:min(last, nOpts)) = iP;
    end

    % --- One descriptor per key/value pair.
    for ii = 1:floor(nOpts/2)
        key = opts{2*ii-1};
        val = opts{2*ii};

        [label, disabled, hidden] = stripPrefixes(key);

        field = genvarname_v2(label);
        iP    = panelOf(2*ii-1);

        e             = emptyDescriptor();
        e(1).Kind     = kindOf(val);
        e(1).Label    = label;
        e(1).Field    = field;
        e(1).Disabled = disabled;
        e(1).Hidden   = hidden;
        e(1).Declared = val;
        e(1).Choices  = {};
        if strcmp(e(1).Kind, 'list'); e(1).Choices = val; end

        if iP > 0
            e(1).Panel       = panelTitle{iP};
            e(1).PanelField  = genvarname_v2(panelTitle{iP});
            e(1).PanelHidden = startsWithTwo(panelTitle{iP}, '##');
            e(1).Handle      = [e(1).PanelField '_' field];
        else
            e(1).Panel       = '';
            e(1).PanelField  = '';
            e(1).PanelHidden = false;
            e(1).Handle      = field;
        end

        d(end+1) = e; %#ok<AGROW>
    end
end

% ----------------------------------------------------------------------------
function [label, disabled, hidden] = stripPrefixes(key)
% Byte-for-byte the generator's order and arithmetic. It tests two characters and
% removes two, even though the documented markers are three, and it tests '**'
% against whatever '##' left behind. Both are preserved -- see the header.
    disabled = false;
    hidden   = false;
    label    = key;

    if startsWithTwo(label, '##')
        label = label(3:end);
        disabled = true;
    end
    if startsWithTwo(label, '**')
        label = label(3:end);
        hidden = true;
    end
end

function tf = startsWithTwo(s, marker)
% The generator indexes (1:2) unguarded, which errors on a one-character name.
% Guarding is the one deviation here: it cannot change any existing model's
% output, because a name that short would have thrown before reaching a widget.
    tf = ischar(s) && numel(s) >= 2 && strcmp(s(1:2), marker);
end

function k = kindOf(val)
% The generator's dispatch, in its order. 'button' is last because 'pushbutton'
% is a char and would otherwise be caught by nothing else anyway.
    if islogical(val)
        k = 'checkbox';
    elseif isnumeric(val) && numel(val) == 1
        k = 'number';
    elseif iscell(val)
        k = 'list';
    elseif isnumeric(val) && numel(val) > 1
        k = 'table';
    elseif ischar(val) && strcmp(val, 'pushbutton')
        k = 'button';
    else
        k = 'unsupported';   % the generator silently creates nothing for these
    end
end

function d = emptyDescriptor()
    d = struct('Kind', {}, 'Label', {}, 'Field', {}, 'Handle', {}, ...
               'Panel', {}, 'PanelField', {}, 'PanelHidden', {}, ...
               'Disabled', {}, 'Hidden', {}, 'Declared', {}, 'Choices', {});
end
