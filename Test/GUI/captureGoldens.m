function captureGoldens(outDir, models, sizes)
%captureGoldens  Screenshot AND content inventory for the windows, before/after a change.
%
%   captureGoldens(outDir)                  the default coverage set, at one size
%   captureGoldens(outDir, models)          {'inversion_recovery', ...}
%   captureGoldens(outDir, models, sizes)   [w h; w h; ...] main-window sizes
%
%   WHY THE INVENTORY AND NOT JUST THE PNG
%
%   Stage D1 emptied the whole Datasets panel -- Path data, Browse, Study ID, Download
%   example, IRData, Mask -- with all 25 tests green, because geomAudit walks CONTAINERS
%   and a container with no children passes trivially. A PNG would have shown it, but a
%   PNG cannot be diffed in review: a reviewer sees two images and has to spot the
%   difference by eye.
%
%   So every capture writes two artefacts:
%       <label>.png    what it looks like       (for a human to LOOK at)
%       <label>.txt    what is actually in it   (for `diff` to read)
%
%   The .txt is one sorted line per LEAF component -- class, tag, the text it displays,
%   visibility, and pixel size. Sorted by the container breadcrumb, so a component that
%   moves between panels shows up as a move, and a component that vanishes shows up as a
%   deletion. It records CONTENT, not just geometry, which is the assertion Stage D1
%   was missing.
%
%   Position is deliberately reported via getpixelposition, not the Position property:
%   once a component is managed by a uigridlayout, its Position property is no longer
%   authoritative, and Stage E moves most of these components into grids.
%
%   Sizes are rounded to whole pixels. Sub-pixel jitter between runs is noise, and noise
%   in a golden makes the golden useless.
%
%   Usage before and after a layout change:
%       captureGoldens('Test/GUI/evidence/before_E1')
%       ... make the change ...
%       captureGoldens('Test/GUI/evidence/after_E1')
%       diff -ru Test/GUI/evidence/before_E1 Test/GUI/evidence/after_E1   (*.txt only)
%
%   See also: geomAudit, resizeCheck, Test/GUI/tMainApp.m

    arguments
        outDir {mustBeTextScalar}
        % The coverage set, chosen for the ways the generated UI can go wrong:
        %   inversion_recovery  the default model, smallest case
        %   mp2rage             the most MRIinputs -- the tallest Datasets panel
        %   qmt_spgr            13 option rows -- the tallest Options panel
        %   qsm_sb              16 rows, and the only linkGUIState user
        %   mt_sat              setPanelInvisible, 4 inputs
        %   dti                 the asymmetric ###/*** handling the plan forbids changing
        models cell = {'inversion_recovery','mp2rage','qmt_spgr','qsm_sb','mt_sat','dti'}
        sizes  double = [1126 837]
    end

    if ~exist(outDir, 'dir'); mkdir(outDir); end
    fprintf('captureGoldens -> %s\n', outDir);

    for m = 1:numel(models)
        name = models{m};
        for s = 1:size(sizes, 1)
            sz = sizes(s, :);
            tag = name;
            if size(sizes, 1) > 1
                tag = sprintf('%s_%dx%d', name, sz(1), sz(2));
            end
            try
                captureOne(outDir, name, tag, sz);
            catch ME
                fprintf('  !! %s FAILED: %s\n', tag, ME.message);
                writeLines(fullfile(outDir, [tag '_ERROR.txt']), ...
                    {sprintf('%s: %s', ME.identifier, ME.message)});
            end
            closeEverything();
        end
    end
    fprintf('done.\n');
end

% ----------------------------------------------------------------------------
function captureOne(outDir, modelName, tag, sz)
    closeEverything();

    Model = feval(modelName);
    qMRLab(Model);
    drawnow;

    main = findall(groot, 'Type', 'figure', 'Name', 'qMRLab');
    assert(~isempty(main), 'main window did not open for %s', modelName);
    main = main(1);

    % A visible window is not cosmetic here: SizeChangedFcn does not fire for an
    % invisible figure, so an invisible capture measures the construction-time
    % layout and not the one a user would see.
    main.Visible = 'on';
    main.Position(3:4) = sz;
    drawnow; pause(1.5); drawnow;

    emit(outDir, [tag '_main'], main);

    % The Options window is built lazily by the main app; open it the way a user does.
    opts = findall(groot, 'Tag', 'OptionsGUI');
    if isempty(opts)
        btn = findall(main, 'Tag', 'OpenOptionsPanel');
        if ~isempty(btn) && ~isempty(btn(1).ButtonPushedFcn)
            try, btn(1).ButtonPushedFcn(btn(1), []); catch, end
            drawnow; pause(1);
            opts = findall(groot, 'Tag', 'OptionsGUI');
        end
    end
    if ~isempty(opts)
        opts = opts(1);
        opts.Visible = 'on';
        drawnow; pause(1); drawnow;
        emit(outDir, [tag '_options'], opts);
    else
        fprintf('  (no Options window for %s)\n', modelName);
    end
end

% ----------------------------------------------------------------------------
function emit(outDir, label, fig)
    png = fullfile(outDir, [label '.png']);
    try
        exportapp(fig, png);
    catch
        try
            imwrite(frame2im(getframe(fig)), png);
        catch ME
            fprintf('  (no image for %s: %s)\n', label, ME.message);
        end
    end

    lines = inventory(fig);
    writeLines(fullfile(outDir, [label '.txt']), lines);
    fprintf('  %-34s %3d components\n', label, numel(lines) - 1);
end

% ----------------------------------------------------------------------------
function lines = inventory(fig)
%INVENTORY  One line per leaf component: where it is, what it is, what it SAYS.
    rows = {};
    figPos = getpixelposition(fig);
    walk(fig, '');

    rows = sort(rows);
    lines = [{sprintf('# %s  %dx%d  %d components', fig.Name, ...
                      round(figPos(3)), round(figPos(4)), numel(rows))}, rows];

    function walk(parent, path)
        kids = allchild(parent);
        for k = 1:numel(kids)
            h = kids(k);
            if ~isgraphics(h); continue; end
            name = shortClass(h);
            if isprop(h, 'Tag') && ~isempty(get(h, 'Tag'))
                name = sprintf('%s[%s]', name, get(h, 'Tag'));
            end
            here = [path '/' name];

            % Not every graphics object has Children -- matlab.ui.control.Image
            % throws on allchild rather than returning empty.
            grandkids = gobjects(0);
            if isprop(h, 'Children'); grandkids = allchild(h); end
            if isempty(grandkids)
                rows{end+1} = describe(h, here); %#ok<AGROW>
            else
                % A container still gets a line: an emptied panel must be visible in
                % the diff as a container whose child count went to zero.
                rows{end+1} = sprintf('%-78s  %-10s  children=%d', ...
                    here, visOf(h), numel(grandkids)); %#ok<AGROW>
                walk(h, here);
            end
        end
    end

    function s = describe(h, here)
        s = sprintf('%-78s  %-10s  %-22s  %-46s  %s', here, visOf(h), sizeOf(h), colourOf(h), textOf(h));
    end
end

function v = visOf(h)
    v = 'vis=?';
    if isprop(h, 'Visible'); v = ['vis=' char(string(get(h, 'Visible')))]; end
end

function c = colourOf(h)
%COLOUROF  The colours a component actually paints with.
%
%   Without this a theming regression diffs completely clean: the inventory
%   recorded text, visibility and size, and D2 changes none of those. Rounded to
%   two decimals so sub-pixel palette jitter between runs is not mistaken for a
%   change, and omitted entirely when a component states no colour of its own --
%   which is the POINT of D2, so "no entry here" is the healthy state.
    c = '';
    for p = {'BackgroundColor', 'FontColor', 'ForegroundColor', 'Color'}
        if ~isprop(h, p{1}); continue; end
        try
            v = get(h, p{1});
        catch
            continue
        end
        if ~isnumeric(v) || numel(v) ~= 3; continue; end
        c = [c sprintf(' %s=%s', p{1}(1:2), mat2str(round(v, 2)))]; %#ok<AGROW>
    end
    c = strtrim(c);
end

function s = sizeOf(h)
    s = 'px=n/a';
    try
        p = getpixelposition(h, true);
        s = sprintf('px=%dx%d@%d,%d', round(p(3)), round(p(4)), round(p(1)), round(p(2)));
    catch
    end
end

function t = textOf(h)
%TEXTOF  What the component actually displays. This is the whole point of the file.
    t = '';
    try
        for p = {'Text','String','Title','Items','Value','Data','Placeholder'}
            if ~isprop(h, p{1}); continue; end
            v = get(h, p{1});
            if isempty(v); continue; end
            % A legacy uicontrol calls its caption String and a native component
            % calls it Text. Emit both under Text so converting a control from one
            % to the other reads as "same caption" instead of one deletion plus one
            % addition. The class is still on the line, so a genuine type change is
            % still visible -- it just does not drown the caption diff.
            name = p{1};
            if strcmp(name, 'String'); name = 'Text'; end
            t = [t sprintf(' %s=%s', name, flatten(v))]; %#ok<AGROW>
        end
    catch
    end
    t = strtrim(t);
    if numel(t) > 160; t = [t(1:157) '...']; end
end

function s = flatten(v)
    if ischar(v)
        s = ['"' strrep(v, newline, '\n') '"'];
    elseif isstring(v)
        s = ['"' char(strjoin(v, '|')) '"'];
    elseif iscell(v)
        parts = cellfun(@flatten, v(:)', 'UniformOutput', false);
        s = ['{' strjoin(parts, ',') '}'];
    elseif islogical(v)
        s = mat2str(v);
    elseif isnumeric(v)
        if numel(v) > 12
            s = sprintf('<%s numeric>', mat2str(size(v)));
        else
            s = mat2str(round(v, 4));
        end
    else
        s = ['<' class(v) '>'];
    end
end

function s = shortClass(h)
    s = class(h);
    s = s(find(s == '.', 1, 'last') + 1 : end);
end

function writeLines(path, lines)
    fid = fopen(path, 'w');
    if fid < 0; return; end
    c = onCleanup(@() fclose(fid));
    for k = 1:numel(lines)
        fprintf(fid, '%s\n', lines{k});
    end
end

function closeEverything()
    delete(findall(groot, 'Type', 'figure'));
    for k = {'Model','Data','FileBrowserList','MethodList','Method','version'}
        if isappdata(0, k{1}); rmappdata(0, k{1}); end
    end
    drawnow;
end
