classdef tDSL < matlab.unittest.TestCase
% tDSL  parseButtons must agree with the generator it will replace.
%
%   The `buttons` DSL decides `Model.options` FIELD NAMES, and those names are
%   written into saved FitResults. A renderer that lays the options out
%   differently is a cosmetic change; one that names a field differently is a
%   silent data-format change that only shows up when someone reloads a year-old
%   result. So the parse is pinned against the live generator, for every model,
%   before anything is rewritten on top of it.
%
%   Deliberately compared against GenerateButtonsWithPanels ITSELF rather than an
%   expected list written by hand. A hand-written list encodes what I believed the
%   DSL does; the generator encodes what it actually does, including the two
%   documented misfeatures parseButtons reproduces (see its header).
%
%   These tests are graphics-free apart from the parent figure the generator needs,
%   and run in seconds.
%
%   See also: parseButtons, GenerateButtonsWithPanels, button2opts

    properties
        Fig
    end

    methods (TestClassSetup)
        function requireGraphics(testCase)
            try
                f = figure('Visible', 'off'); delete(f);
            catch ME
                testCase.assumeFail(['No usable graphics environment: ' ME.message]);
            end
        end
    end

    methods (TestMethodSetup)
        function makeFigure(testCase)
            % A legacy figure, not a uifigure: GenerateButtonsWithPanels still
            % builds uicontrols, and this test is about names, not appearance.
            testCase.Fig = figure('Visible', 'off', 'Position', [0 0 600 900]);
            testCase.addTeardown(@() delete(testCase.Fig));
        end
    end

    methods (Test)

        function handleNamesMatchTheGeneratorForEveryModel(testCase)
            % The assertion the whole of E3 rests on.
            for model = string(list_models())'
                m = feval(model);
                if isempty(m.buttons); continue; end

                delete(allchild(testCase.Fig));
                generated = GenerateButtonsWithPanels(m.buttons, testCase.Fig, []);

                % The generator emits a '<tag>lbl' companion for every control that
                % has a separate label. Those are not options and button_handle2opts
                % skips them, so drop them before comparing.
                got = fieldnames(generated);
                got = got(~endsWith(got, 'lbl'));

                d = parseButtons(m.buttons);
                want = {d(~strcmp({d.Kind}, 'unsupported')).Handle}';

                testCase.verifyEqual(sort(got), sort(want), sprintf( ...
                    ['%s: parseButtons and GenerateButtonsWithPanels disagree on ' ...
                     'the control names.\n  only generator: %s\n  only parser   : %s'], ...
                    model, strjoin(setdiff(got, want), ', '), ...
                    strjoin(setdiff(want, got), ', ')));
            end
        end

        function fieldNamesReachTheOptionsStruct(testCase)
            % The other half of the contract: the names parseButtons derives are the
            % names the model actually keeps its options under. button2opts builds
            % Model.options from the same DSL by a separate code path, and the plan
            % keeps the two parallel rather than making one call the other -- so
            % this is the assertion that they have not drifted.
            for model = string(list_models())'
                m = feval(model);
                if isempty(m.buttons) || isempty(fieldnames(m.options)); continue; end

                d = parseButtons(m.buttons);
                d = d(~strcmp({d.Kind}, 'unsupported'));
                have = fieldnames(m.options);

                % Handle, not Field. An option inside a PANEL is stored under the
                % panel-prefixed name -- qmt_spgr keeps its Rician settings at
                % 'Riciannoisebias_Method', never at 'Method'. Getting this wrong is
                % the obvious way to write a renderer that reads the wrong option.
                for k = 1:numel(d)
                    testCase.verifyTrue(any(strcmp(have, d(k).Handle)), sprintf( ...
                        '%s: parseButtons produced option "%s", absent from Model.options (%s).', ...
                        model, d(k).Handle, strjoin(have', ', ')));
                end
            end
        end

        function noFieldNameIsAProperSubstringOfAnother(testCase)
            % getOptionsFieldName resolves options by substring in places, so a name
            % contained in another is an ambiguity waiting to be hit.
            %
            % Three such pairs already exist. They are pre-existing facts about the
            % models, not something this work introduced, and renaming an option to
            % tidy them up would change saved FitResults -- the same trap as the dti
            % asymmetry. So this asserts the set has not GROWN rather than that it is
            % empty: a permanently red test teaches people to ignore it, and an
            % empty-set assertion here could only be satisfied by breaking data
            % compatibility. See Test/GUI/KNOWN_BUGS.md.
            known = { ...
                'qmt_spgr: "R1fT2f" inside "FixR1fT2f"', ...
                'qsm_sb: "LambdaL1" inside "ReOptimizeLambdaL1"', ...
                'qsm_sb: "LambdaL2" inside "ReOptimizeLambdaL2"'};
            offenders = {};
            for model = string(list_models())'
                m = feval(model);
                if isempty(m.buttons); continue; end
                f = {parseButtons(m.buttons).Field};
                for a = 1:numel(f)
                    for b = 1:numel(f)
                        if a ~= b && ~isempty(f{a}) && ~isempty(f{b}) && ...
                                ~strcmp(f{a}, f{b}) && contains(f{b}, f{a})
                            offenders{end+1} = sprintf('%s: "%s" inside "%s"', ...
                                model, f{a}, f{b}); %#ok<AGROW>
                        end
                    end
                end
            end
            fresh = setdiff(offenders, known);
            testCase.verifyEmpty(fresh, sprintf( ...
                ['NEW option-name ambiguities (one field name contains another).\n' ...
                 'getOptionsFieldName resolves by substring, so these can silently\n' ...
                 'address the wrong option:\n  %s'], strjoin(fresh, '\n  ')));

            % And the other direction: if a known pair disappears, someone renamed an
            % option, which changes saved FitResults. That deserves to be noticed too.
            gone = setdiff(known, offenders);
            testCase.verifyEmpty(gone, sprintf( ...
                ['A known option-name pair vanished, so an option was renamed.\n' ...
                 'That changes the key in saved FitResults:\n  %s'], strjoin(gone, '\n  ')));
        end

        function theDtiPrefixAsymmetryIsPreserved(testCase)
            % The specific misfeature the migration plan forbids "fixing", pinned so
            % that a future tidy-up of parseButtons fails here instead of silently
            % renaming an option in everyone's saved results.
            %
            % The generator strips TWO characters from a THREE character marker, and
            % genvarname_v2 then maps the surviving '#' to 'N'.
            withPrefix    = parseButtons({'###Rician noise bias', true});
            withoutPrefix = parseButtons({'Rician noise bias', true});

            testCase.verifyEqual(withPrefix.Field, 'NRiciannoisebias', ...
                'The ### prefix no longer yields the N-prefixed field name.');
            testCase.verifyEqual(withoutPrefix.Field, 'Riciannoisebias');
            testCase.verifyTrue(withPrefix.Disabled, 'The ### prefix should disable.');
            testCase.verifyNotEqual(withPrefix.Field, withoutPrefix.Field, ...
                ['Toggling ### must still rename the field. dti.m:135-137 toggles it ' ...
                 'at runtime; making it symmetric changes saved FitResults.']);
        end

    end
end
