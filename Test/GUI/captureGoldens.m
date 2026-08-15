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

    captureFigure(outDir, [tag '_main'], main);

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
        captureFigure(outDir, [tag '_options'], opts);
    else
        fprintf('  (no Options window for %s)\n', modelName);
    end
end

% ----------------------------------------------------------------------------
function closeEverything()
    delete(findall(groot, 'Type', 'figure'));
    for k = {'Model','Data','FileBrowserList','MethodList','Method','version'}
        if isappdata(0, k{1}); rmappdata(0, k{1}); end
    end
    drawnow;
end
