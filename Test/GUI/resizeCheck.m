function resizeCheck()
%resizeCheck  Does the embedded viewer relayout when the window resizes?
%
%   The one question the headless test suite structurally cannot answer: resize
%   callbacks do not fire for invisible figures, and -batch runs invisible. This
%   needs a real, visible window -- but NOT a hand-drag. Resizing a visible figure
%   programmatically fires exactly the same callbacks, and measuring beats
%   eyeballing.
%
%   Sizes are chosen to fit a laptop display. Run it, then paste the output.
%
%   Usage:  startup; addpath(fullfile(pwd,'Test','GUI')); resizeCheck

    fprintf('\n=== qMRLab embedded-viewer resize check ===\n');
    scr = get(groot, 'ScreenSize');
    fprintf('screen: %d x %d\n', scr(3), scr(4));

    qMRLab(inversion_recovery);
    drawnow; pause(2);
    fig = findall(groot, 'Type', 'figure', 'Name', 'qMRLab');
    if isempty(fig)
        fprintf('FAIL: main window did not open.\n'); return
    end
    fig.Visible = 'on';   % the whole point: callbacks need a visible window

    % Stay inside the display, and leave room for the menu bar / dock.
    small = [1126 837];
    big   = [min(scr(3) - 80, 1500), min(scr(4) - 140, 1000)];
    fprintf('testing %s  ->  %s\n', mat2str(small), mat2str(big));

    a = measure(fig, small);
    b = measure(fig, big);

    fprintf('\n%-22s %14s %14s   %s\n', '', 'small', 'large', 'grew?');
    names = setdiff(fieldnames(a), {'railGap'}, 'stable');   % railGap is a scalar
    for k = 1:numel(names)
        n = names{k};
        grew = b.(n)(3) > a.(n)(3) + 5;   % width tracked the window
        fprintf('%-22s %14s %14s   %s\n', n, mat2str(round(a.(n)(3:4))), ...
            mat2str(round(b.(n)(3:4))), string(grew));
    end

    % The anchoring question: does the tool rail stay at the panel's right edge?
    fprintf('\nright-rail gap from panel edge:  small %.0f px   large %.0f px\n', ...
        a.railGap, b.railGap);
    if abs(b.railGap - a.railGap) <= 4
        fprintf('  ANCHORED (gap unchanged) -- imtool3D is relayouting.\n');
    else
        fprintf('  DRIFTED by %.0f px -- imtool3D SizeChangedFcn is NOT firing.\n', ...
            b.railGap - a.railGap);
    end

    fprintf('\nclamp check: asking for 700x500...\n');
    fig.Position(3:4) = [700 500]; drawnow; pause(1);
    fprintf('  window is now %s (should be about 1126x837)\n', mat2str(round(fig.Position(3:4))));

    fprintf('\n=== done. Paste everything above. ===\n');
end

function m = measure(fig, sz)
    fig.Position(3:4) = sz;
    drawnow; pause(1.5); drawnow;

    m.window      = [0 0 fig.Position(3:4)];
    m.viewerPanel = pos(findall(fig, 'Tag', 'FitResultsPlotPanel'));
    m.imtool3D    = pos(findall(fig, 'Tag', 'imtool3D'));

    ax = findall(fig, 'Type', 'axes');
    m.imageAxes = [0 0 0 0];
    if ~isempty(ax), m.imageAxes = pos(ax(1)); end

    % Rail = the mask-select toggles imtool3D pins to its right edge.
    rail = findall(fig, 'Tag', 'MaskSelected');
    m.railGap = NaN;
    if ~isempty(rail) && ~isequal(m.imtool3D, [0 0 0 0])
        r = getpixelposition(rail(1), true);
        p = getpixelposition(findall(fig, 'Tag', 'imtool3D'), true);
        m.railGap = (p(1) + p(3)) - (r(1) + r(3));
    end
end

function p = pos(h)
    p = [0 0 0 0];
    if ~isempty(h)
        try, p = getpixelposition(h(1), true); catch, end
    end
end
