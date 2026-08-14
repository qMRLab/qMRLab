function defects = geomAudit(fig, label, outDir)
% geomAudit  Find SILENT geometry failures in a figure and capture a screenshot.
%
%   defects = geomAudit(fig)                 audit only, no capture
%   defects = geomAudit(fig, label, outDir)  also writes <outDir>/<label>.png
%
%   Why this exists: the App Designer migration's characteristic failure mode is
%   not an exception -- it is a container that silently collapses to sub-pixel
%   size (a GUIDE-era normalized Position assigned to a pixel-united uipanel), or
%   a child laid out past the edge of its parent (the unclamped downward stacking
%   in GenerateButtonsWithPanels). An error-counting smoke test sees neither.
%
%   Returns a struct array with fields:
%       Kind    'Collapsed' | 'Overflow' | 'OffFigure'
%       Type    the graphics class
%       Tag     the component Tag, if any
%       Path    Tag/Type breadcrumb from the figure down
%       Detail  human-readable description
%
%   Example -- audit both qMRLab windows for every model:
%       defects = runBranchTriage();
%
%   See also: runBranchTriage, tCapabilities

    arguments
        fig     matlab.ui.Figure
        label   {mustBeTextScalar} = ''
        outDir  {mustBeTextScalar} = ''
    end

    % px. GenerateButtonsWithPanels lays option groups out at a deliberate 35 px
    % per row, so a legitimate single-option panel is ~34 px tall -- a 40 px floor
    % flags those as defects. 20 px is below anything that can render content.
    MIN_SIZE  = 20;
    EDGE_TOL  = 3;    % px of overhang to tolerate before calling it an overflow

    % Subtrees to skip. imtool3D is vendored third-party code that lays itself out
    % in pixels and legitimately uses 30 px slider rails and 20 px info strips --
    % auditing inside it produces only false positives. Its own correctness is
    % covered by Test/GUI/tCapabilities.m instead.
    SKIP_TAGS = {'imtool3D'};

    defects = emptyDefect();
    drawnow;   % positions are not final until the layout has settled

    figPos = getpixelposition(fig);
    walk(fig, sprintf('%s', class(fig)));

    if ~isempty(label) && ~isempty(outDir)
        if ~exist(outDir, 'dir'); mkdir(outDir); end
        png = fullfile(outDir, [matlab.lang.makeValidName(label) '.png']);
        try
            exportapp(fig, png);
        catch
            % exportapp needs a visible figure; fall back to a frame grab.
            try
                imwrite(frame2im(getframe(fig)), png);
            catch ME
                warning('geomAudit:capture', 'Could not capture %s: %s', label, ME.message);
            end
        end
    end

    % ------------------------------------------------------------------
    function walk(parent, path)
        kids = allchild(parent);
        for k = 1:numel(kids)
            h = kids(k);
            if ~isContainerLike(h) || ~isVisible(h)
                continue
            end
            if isprop(h, 'Tag') && any(strcmp(get(h, 'Tag'), SKIP_TAGS))
                continue    % do not descend into vendored, pixel-designed subtrees
            end

            name = describe(h);
            here = [path ' > ' name];

            try
                inFig = getpixelposition(h, true);   % relative to the figure
                inPar = getpixelposition(h);         % relative to the parent
            catch
                continue    % some components (e.g. layout-managed) have no pixel position
            end

            if inPar(3) < MIN_SIZE || inPar(4) < MIN_SIZE
                defects(end+1) = mkDefect('Collapsed', h, here, sprintf( ...
                    'size %.1f x %.1f px is below the %d px floor', ...
                    inPar(3), inPar(4), MIN_SIZE)); %#ok<AGROW>
            end

            parPos = getpixelposition(parent);
            if ~isa(parent, 'matlab.ui.Figure')
                overRight = (inPar(1) + inPar(3)) - parPos(3);
                overTop   = (inPar(2) + inPar(4)) - parPos(4);
                if inPar(1) < -EDGE_TOL || inPar(2) < -EDGE_TOL || ...
                        overRight > EDGE_TOL || overTop > EDGE_TOL
                    defects(end+1) = mkDefect('Overflow', h, here, sprintf( ...
                        'extends outside its parent (left %.1f, bottom %.1f, right +%.1f, top +%.1f)', ...
                        inPar(1), inPar(2), overRight, overTop)); %#ok<AGROW>
                end
            end

            if (inFig(1) + inFig(3)) < 0 || (inFig(2) + inFig(4)) < 0 || ...
                    inFig(1) > figPos(3) || inFig(2) > figPos(4)
                defects(end+1) = mkDefect('OffFigure', h, here, sprintf( ...
                    'lies entirely outside the window at [%.1f %.1f %.1f %.1f]', inFig)); %#ok<AGROW>
            end

            walk(h, here);
        end
    end
end

% ----------------------------------------------------------------------
function tf = isContainerLike(h)
    tf = isgraphics(h) && ( ...
        isa(h, 'matlab.ui.container.Panel')       || ...
        isa(h, 'matlab.ui.container.ButtonGroup') || ...
        isa(h, 'matlab.ui.container.Tab')         || ...
        isa(h, 'matlab.ui.container.TabGroup')    || ...
        isa(h, 'matlab.ui.container.GridLayout')  || ...
        isa(h, 'matlab.ui.control.UIAxes')        || ...
        isa(h, 'matlab.graphics.axis.Axes')       || ...
        isa(h, 'matlab.ui.control.Table')         || ...
        (isprop(h, 'Style') && strcmp(get(h, 'Style'), 'frame')));
end

function tf = isVisible(h)
    tf = ~isprop(h, 'Visible') || strcmp(get(h, 'Visible'), 'on');
end

function s = describe(h)
    s = class(h);
    s = s(find(s == '.', 1, 'last') + 1 : end);
    if isprop(h, 'Tag') && ~isempty(get(h, 'Tag'))
        s = sprintf('%s[%s]', s, get(h, 'Tag'));
    end
end

function d = emptyDefect()
    d = struct('Kind', {}, 'Type', {}, 'Tag', {}, 'Path', {}, 'Detail', {});
end

function d = mkDefect(kind, h, path, detail)
    tag = '';
    if isprop(h, 'Tag'); tag = get(h, 'Tag'); end
    d = struct('Kind', kind, 'Type', class(h), 'Tag', tag, 'Path', path, 'Detail', detail);
end
