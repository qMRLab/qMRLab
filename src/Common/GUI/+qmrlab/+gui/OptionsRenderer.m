classdef OptionsRenderer
%OptionsRenderer  Draw a model's options from parseButtons descriptors, on a grid.
%
%   h = qmrlab.gui.OptionsRenderer.render(model, parent)
%   h = qmrlab.gui.OptionsRenderer.render(model, parent, changedFcn)
%
%   Returns the same struct of handles GenerateButtonsWithPanels returns -- same
%   field names, one per option -- so button_handle2opts and every caller that
%   reads it keep working. parseButtons derives those names and Test/GUI/tDSL.m
%   pins them against the generator for all 22 models.
%
%   WHAT THIS REPLACES, AND WHY A GRID RATHER THAN BETTER ARITHMETIC
%
%   GenerateButtonsWithPanels lays options out with hybrid units: each row is a
%   fixed 35 px, expressed as 35/panelHeight, while the gap between groups is a
%   flat 0.02 of the panel. The stack then walks DOWN from y = 1 with no floor.
%   Three consequences, all observed:
%
%     * The total height needed grows with the panel, so the layout can overflow a
%       TALLER container than it fitted. Making the options column 18 px taller
%       pushed qsm_sb's last group 3.4 px out the bottom.
%     * Nothing stops the walk at 0, so with enough options the last groups land
%       off-panel. qmt_spgr (13 rows) and qsm_sb (16) are the models that do it.
%     * Because the groups are siblings of the Save/Load/Default/Help row rather
%       than being separated from it, they overlap it. Measured on qsm_sb before
%       any of this work: all four buttons sat under a generated panel.
%
%   None of that is fixable by adjusting the constants -- a fixed-height stack in a
%   fixed-height box either fits or does not. A scrollable grid is what makes the
%   overflow reachable instead of lost, which is the same answer E2 used for the
%   Datasets panel and E4 for the viewer's control strip.
%
%   GenerateButtonsWithPanels is NOT deleted and NOT dispatched inside. It still
%   serves the three Sim add-on windows, which are legacy figures where a
%   uigridlayout cannot host uicontrols at all. Those keep the old path until
%   Stage F; this class is chosen by the caller, which knows it is a uifigure.
%
%   See also: parseButtons, button_handle2opts, GenerateButtonsWithPanels

    properties (Constant, Access = private)
        ROWGAP   = 4
        GROUPGAP = 6
        PAD      = 6
        % Proportional, like the widget it replaces: the generator put the label at
        % x=0.05 width 0.5 and the control at x=0.45 width 0.5. A fixed 150 px label
        % looked reasonable until measured in the real column, which is only ~250 px
        % wide -- it left ~90 px for the control and truncated "0.000921055" to
        % "0.0009210" and "forward" to "for...".
    end

    methods (Static)

        function handles = render(model, parent, changedFcn)
            if nargin < 3; changedFcn = []; end
            handles = struct();

            delete(allchild(parent));
            d = parseButtons(model.buttons);
            d = d(~strcmp({d.Kind}, 'unsupported'));
            if isempty(d); return; end

            groups = qmrlab.gui.OptionsRenderer.groupOf(d);
            nGroup = max(groups);

            outer = uigridlayout(parent, [max(nGroup,1) 1]);
            outer.ColumnWidth = {'1x'};
            outer.RowHeight   = repmat({'fit'}, 1, max(nGroup,1));
            outer.Padding     = repmat(qmrlab.gui.OptionsRenderer.PAD, 1, 4);
            outer.RowSpacing  = qmrlab.gui.OptionsRenderer.GROUPGAP;
            % The whole point: options that do not fit are reachable rather than
            % drawn off the bottom of the panel.
            outer.Scrollable  = 'on';

            for g = 1:nGroup
                inGroup = d(groups == g);
                handles = qmrlab.gui.OptionsRenderer.renderGroup( ...
                    inGroup, outer, g, model, changedFcn, handles);
            end
        end

    end

    methods (Static, Access = private)

        function g = groupOf(d)
            % Consecutive descriptors sharing a panel form one group; runs of
            % panel-less options form their own. Same grouping the generator makes
            % from its NumPanel / NumNoPanel arithmetic, expressed directly.
            g = zeros(1, numel(d));
            cur = 0;
            last = char(0);
            for k = 1:numel(d)
                key = d(k).PanelField;
                if k == 1 || ~strcmp(key, last)
                    cur = cur + 1;
                end
                g(k) = cur;
                last = key;
            end
        end

        function handles = renderGroup(d, outer, row, model, changedFcn, handles)
            C = qmrlab.gui.OptionsRenderer;
            inPanel = ~isempty(d(1).PanelField);

            if inPanel
                host = uipanel(outer, 'Title', strrep(d(1).Panel, '#', ''), ...
                    'FontSize', 11, 'FontWeight', 'bold');
                host.Layout.Row = row;  host.Layout.Column = 1;
                if d(1).PanelHidden
                    % '##' on a panel title hides the group. Hiding alone leaves the
                    % row occupying space -- measured -- so collapse it too.
                    host.Visible = 'off';
                    outer.RowHeight{row} = 0;
                end
                inner = uigridlayout(host, [numel(d) 1]);
            else
                inner = uigridlayout(outer, [numel(d) 1]);
                inner.Layout.Row = row;  inner.Layout.Column = 1;
            end
            inner.ColumnWidth = {'1x'};
            inner.RowHeight   = repmat({'fit'}, 1, numel(d));
            inner.Padding     = repmat(C.PAD, 1, 4);
            inner.RowSpacing  = C.ROWGAP;

            for k = 1:numel(d)
                handles = C.renderOne(d(k), inner, k, model, changedFcn, handles);
            end
        end

        function handles = renderOne(e, inner, row, model, changedFcn, handles)
            C = qmrlab.gui.OptionsRenderer;
            value = C.valueFor(e, model);

            switch e.Kind
                case {'checkbox', 'button'}
                    % No separate label: the control carries its own caption, which
                    % is what the generator does for these two as well.
                    if strcmp(e.Kind, 'checkbox')
                        ctrl = uicheckbox(inner, 'Text', e.Label, 'Value', logical(value));
                    else
                        ctrl = uibutton(inner, 'state', 'Text', e.Label, 'Value', false);
                    end
                    ctrl.Layout.Row = row;  ctrl.Layout.Column = 1;
                    lbl = gobjects(0);
                    rowHost = gobjects(0);

                otherwise
                    pair = uigridlayout(inner, [1 2]);
                    rowHost = pair;
                    pair.Layout.Row = row;  pair.Layout.Column = 1;
                    pair.ColumnWidth   = {'1x', '1x'};
                    pair.RowHeight     = {'fit'};
                    pair.Padding       = [0 0 0 0];
                    pair.ColumnSpacing = 6;

                    lbl = uilabel(pair, 'Text', [e.Label ':'], 'HorizontalAlignment', 'left');
                    lbl.Layout.Row = 1;  lbl.Layout.Column = 1;

                    switch e.Kind
                        case 'number'
                            % A TEXT field, not uieditfield('numeric'), even though
                            % the numeric one validates input for free and
                            % round-trips exactly where str2num loses precision.
                            %
                            % Because a "numeric" option does not always hold a
                            % number. dti declares Rician noise bias numerically and
                            % then assigns options.Riciannoisebias_value = 'auto' in
                            % UpdateFields; qmt_spgr and qmt_sirfse put 'R1MAP',
                            % 'R1f' and '(R1f*T2f)/R1f' in the fitting Start column.
                            % Those are load-bearing modelling sentinels the ADR
                            % forbids touching, and a numeric field rejects every one
                            % of them outright ("Value must be a double scalar").
                            %
                            % So this matches the legacy widget exactly: text in,
                            % str2num out. Including the consequence that str2num
                            % turns a sentinel into [] on read-back -- a real
                            % pre-existing bug, recorded in Test/GUI/KNOWN_BUGS.md,
                            % NOT introduced or fixed here.
                            % sprintf('%g'), matching what set(uicontrol,'String',d)
                            % does -- SIX significant digits. This is a round trip
                            % through text, so the formatting IS the stored value:
                            % str2num reads back whatever was printed.
                            %
                            % Measured, after getting it wrong twice. string() keeps
                            % full precision and num2str keeps five; the legacy widget
                            % keeps six. Each variant changed the same four options --
                            % mtv/CSFT1threshold, qmt_spgr/MT_Pulse_Fermitransitiona,
                            % qsm_sb/L1Panel_LambdaL1 and L2Panel_LambdaL2 -- and those
                            % values land in saved FitResults, so "more precise" is
                            % still a payload change and not this commit's business.
                            ctrl = uieditfield(pair, 'text', 'Value', C.asText(value));
                        case 'list'
                            items = cellfun(@(x) char(string(x)), e.Choices, ...
                                            'UniformOutput', false);
                            ctrl = uidropdown(pair, 'Items', items);
                            if ischar(value) && any(strcmp(items, value))
                                ctrl.Value = value;
                            end
                        case 'table'
                            ctrl = uitable(pair, 'Data', value);
                            ctrl.ColumnEditable = true(1, size(value, 2));
                            % '1x' per column: the generator measured the panel and
                            % divided, which threw BadColumnWidthValue whenever the
                            % panel had collapsed. A weight cannot be invalid.
                            ctrl.ColumnWidth = repmat({'1x'}, 1, size(value, 2));
                            if size(value, 1) < 5; ctrl.RowName = {}; end
                            if size(value, 2) < 5; ctrl.ColumnName = {}; end
                    end
                    ctrl.Layout.Row = 1;  ctrl.Layout.Column = 2;
            end

            if e.Disabled; ctrl.Enable = 'off'; end
            if e.Hidden
                % '***' hides an option. Three steps, because one is not enough:
                % hide the control, COLLAPSE its row (a hidden component keeps its
                % cell, measured), and hide the row's container -- otherwise the
                % label pair survives as a visible zero-height box, which is a
                % defect by geomAudit's reckoning and rightly so.
                ctrl.Visible = 'off';
                if ~isempty(lbl); lbl.Visible = 'off'; end
                if ~isempty(rowHost) && isvalid(rowHost); rowHost.Visible = 'off'; end
                inner.RowHeight{row} = 0;
            end

            C.applyTip(e, model, ctrl, lbl);

            if ~isempty(changedFcn)
                if isa(ctrl, 'matlab.ui.control.Table')
                    ctrl.CellEditCallback = changedFcn;
                else
                    ctrl.ValueChangedFcn = changedFcn;
                end
            end

            % Stamp the option name onto the control. The handles struct is
            % private to the window, so this is how a test can ask "which control
            % shows option X" without reaching inside the app.
            setappdata(ctrl, 'optField', e.Handle);
            handles.(e.Handle) = ctrl;
        end

        function t = asText(v)
            if ischar(v)
                t = v;                       % sentinels such as dti's 'auto'
            elseif isnumeric(v) && isscalar(v)
                t = sprintf('%g', v);
            else
                t = char(string(v));
            end
        end

        function v = valueFor(e, model)
            % The live option wins over the declared default -- the declaration is
            % only what the model shipped with, and UpdateFields rewrites options at
            % runtime. Falls back to Declared so the renderer also works on a bare
            % buttons cell with no model behind it.
            v = e.Declared;
            try
                if isfield(model.options, e.Handle)
                    v = model.options.(e.Handle);
                end
            catch
            end
            if isempty(v) && strcmp(e.Kind, 'table'); v = e.Declared; end
        end

        function applyTip(e, model, ctrl, lbl)
            % Tips are keyed by the same mangling as option names. The generator put
            % the tip on the LABEL when there is one, because a tooltip on a table
            % swallows cell interaction; keep that.
            try
                tips = model.tips;
            catch
                return
            end
            if isempty(tips); return; end
            keys = cellfun(@genvarname_v2, tips(1:2:end), 'UniformOutput', false);
            hit  = find(strcmp(keys, e.Field), 1);
            if isempty(hit); return; end
            text = tips{2*hit};
            if ~isempty(lbl)
                lbl.Tooltip = text;
            else
                ctrl.Tooltip = text;
            end
        end

    end
end
