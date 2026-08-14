function results = runBranchTriage(varargin)
% runBranchTriage  Audit every qMRLab window, for every model, for silent geometry bugs.
%
%   results = runBranchTriage()
%   results = runBranchTriage('Models', {'qmt_spgr','qsm_sb'}, 'OutDir', 'my/dir')
%
%   Opens the qMRLab GUI once per model, audits the main window and the Options
%   window with geomAudit, captures a PNG of each, and writes a markdown report.
%
%   This is Stage A2 of the GUI migration plan. Its output is the input to the
%   kill criterion: if more than 8 defects are NOT one-line position/property
%   fixes, abandon the salvage of origin/mb/appmigration and restart from master.
%
%   Run it against whichever GUI is on the path -- the legacy GUIDE app for a
%   baseline, or the migrated app for the triage.
%
%   See also: geomAudit, tCapabilities

    p = inputParser;
    p.addParameter('Models', {}, @(x) iscellstr(x) || isstring(x));
    p.addParameter('OutDir', fullfile(fileparts(mfilename('fullpath')), 'triage'), @(x) ischar(x) || isstring(x));
    p.parse(varargin{:});
    outDir = char(p.Results.OutDir);

    models = cellstr(p.Results.Models);
    if isempty(models) || (isscalar(models) && isempty(models{1}))
        models = list_models();
    end

    if ~exist(outDir, 'dir'); mkdir(outDir); end
    fprintf('Auditing %d models -> %s\n', numel(models), outDir);

    results = struct('Model', {}, 'Window', {}, 'Status', {}, 'Defects', {}, 'Error', {});

    % Close anything left over from a previous run so stale windows are not
    % mistaken for this run's output.
    closeAllQMRWindows();
    cleanup = onCleanup(@closeAllQMRWindows);

    for iModel = 1:numel(models)
        method = models{iModel};
        fprintf('  [%2d/%2d] %-22s ', iModel, numel(models), method);

        try
            Model = feval(method);
            qMRLab(Model);
            drawnow; pause(0.4);   % let the Options window build
        catch ME
            fprintf('LAUNCH FAILED: %s\n', ME.message);
            results(end+1) = mkRow(method, 'launch', 'error', geomAuditEmpty(), ME.message); %#ok<AGROW>
            closeAllQMRWindows();
            continue
        end

        windows = { ...
            'main',    findWindow('qMRLab',    'qMRILab'); ...
            'options', findWindow('OptionsGUI', 'OptionsGUI')};

        for iWin = 1:size(windows, 1)
            winName = windows{iWin, 1};
            fig     = windows{iWin, 2};

            if isempty(fig)
                fprintf('[%s: MISSING] ', winName);
                results(end+1) = mkRow(method, winName, 'missing', geomAuditEmpty(), ''); %#ok<AGROW>
                continue
            end

            try
                d = geomAudit(fig, sprintf('%s_%s', method, winName), outDir);
                status = 'ok'; if ~isempty(d); status = 'defects'; end
                results(end+1) = mkRow(method, winName, status, d, ''); %#ok<AGROW>
                fprintf('[%s: %d] ', winName, numel(d));
            catch ME
                results(end+1) = mkRow(method, winName, 'error', geomAuditEmpty(), ME.message); %#ok<AGROW>
                fprintf('[%s: ERROR] ', winName);
            end
        end
        fprintf('\n');
        closeAllQMRWindows();
    end

    % Per-run JSON so the caller can shard across processes and merge afterwards.
    % One MATLAB process per model is the only reliable isolation: qMRLab caches
    % browser objects holding graphics handles, and they survive both figure
    % teardown and a root-appdata wipe, poisoning the next launch in-process.
    jsonPath = fullfile(outDir, sprintf('results_%s.json', models{1}));
    fid = fopen(jsonPath, 'w');
    fprintf(fid, '%s', jsonencode(results));
    fclose(fid);

    reportPath = fullfile(outDir, 'branch_triage.md');
    writeReport(results, reportPath, outDir);
    fprintf('\nReport: %s\n', reportPath);
    summarize(results);
end

% ----------------------------------------------------------------------
function fig = findWindow(name, tag)
% findall, not findobj -- a uifigure defaults to HandleVisibility='off'.
    fig = findall(groot, 'Type', 'figure', 'Name', name);
    if isempty(fig)
        fig = findall(groot, 'Type', 'figure', 'Tag', tag);
    end
    if numel(fig) > 1; fig = fig(1); end
end

function closeAllQMRWindows()
% Deleting the figure is NOT enough for an App Designer app. The app object stays
% registered as the running singleton, so the next launch resolves to a stale
% instance and dies with "Invalid or deleted object". Delete the app first.
    figs = findall(groot, 'Type', 'figure');
    for k = 1:numel(figs)
        f = figs(k);
        if isprop(f, 'RunningAppInstance') && ~isempty(f.RunningAppInstance)
            try, delete(f.RunningAppInstance); catch, end %#ok<NOCOM>
        end
    end
    names = {'qMRLab', 'OptionsGUI'};
    tags  = {'qMRILab', 'OptionsGUI', 'Simu'};
    for k = 1:numel(names)
        delete(findall(groot, 'Type', 'figure', 'Name', names{k}));
    end
    for k = 1:numel(tags)
        delete(findall(groot, 'Type', 'figure', 'Tag', tags{k}));
    end
    delete(findall(0, 'tag', 'TMWWaitbar'));
    drawnow;
end

function d = geomAuditEmpty()
    d = struct('Kind', {}, 'Type', {}, 'Tag', {}, 'Path', {}, 'Detail', {});
end

function row = mkRow(model, window, status, defects, err)
    row = struct('Model', model, 'Window', window, 'Status', status, ...
                 'Defects', {defects}, 'Error', err);
end

% ----------------------------------------------------------------------
function writeReport(results, path, outDir)
    fid = fopen(path, 'w');
    c = onCleanup(@() fclose(fid));

    fprintf(fid, '# qMRLab GUI geometric triage\n\n');
    fprintf(fid, '- MATLAB: %s (%s)\n', version('-release'), computer('arch'));
    fprintf(fid, '- Generated: %s\n', datestr(now, 'yyyy-mm-dd HH:MM')); %#ok<TNOW1,DATST>
    fprintf(fid, '- Screenshots: `%s`\n\n', outDir);

    nDefects = sum(cellfun(@numel, {results.Defects}));
    nBroken  = numel(unique({results(~strcmp({results.Status}, 'ok')).Model}));
    fprintf(fid, '**%d defects across %d affected models.**\n\n', nDefects, nBroken);

    fprintf(fid, '## Summary\n\n| Model | Window | Status | Defects |\n|---|---|---|---|\n');
    for k = 1:numel(results)
        fprintf(fid, '| %s | %s | %s | %d |\n', results(k).Model, results(k).Window, ...
            results(k).Status, numel(results(k).Defects));
    end

    fprintf(fid, '\n## Detail\n\n');
    for k = 1:numel(results)
        r = results(k);
        if isempty(r.Defects) && isempty(r.Error); continue; end
        fprintf(fid, '### %s / %s\n\n', r.Model, r.Window);
        if ~isempty(r.Error)
            fprintf(fid, '```\nERROR: %s\n```\n\n', r.Error);
        end
        for j = 1:numel(r.Defects)
            d = r.Defects(j);
            fprintf(fid, '- **%s** `%s` — %s\n  - `%s`\n', d.Kind, d.Tag, d.Detail, d.Path);
        end
        fprintf(fid, '\n');
    end
end

function summarize(results)
    nDefects = sum(cellfun(@numel, {results.Defects}));
    broken   = unique({results(~strcmp({results.Status}, 'ok')).Model});
    fprintf('\n%d defects across %d affected models: %s\n', ...
        nDefects, numel(broken), strjoin(broken, ', '));
    fprintf(['\nKILL CRITERION: if more than 8 of these are NOT one-line ' ...
             'position/property fixes,\nabandon the salvage and restart from master.\n']);
end
