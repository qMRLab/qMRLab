function captureFigure(outDir, label, fig)
%captureFigure  Screenshot AND content inventory for one figure.
%
%   Extracted from captureGoldens so the Sim add-on windows can be captured with
%   the SAME format as the main and options windows -- a golden that is a
%   different shape from the one next to it cannot be diffed against it, and
%   Stage F2 rewrites five windows whose only evidence is these files.
%
%   Writes two artefacts, for the two different readers:
%       <label>.png    what it looks like       (for a human to LOOK at)
%       <label>.txt    what is actually in it   (for `diff` to read)
%
%   See also: captureGoldens, geomAudit

    if ~exist(outDir, 'dir'); mkdir(outDir); end
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
