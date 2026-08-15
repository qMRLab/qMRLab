function captureSimGoldens(outDir, modelName)
%captureSimGoldens  Screenshot and inventory for the five Sim add-on windows.
%
%   captureSimGoldens(outDir)             uses charmed, the only model with all five
%   captureSimGoldens(outDir, 'dti')      any model that declares Sim_ methods
%
%   Stage F2 rebuilds these five windows programmatically, dropping their .fig
%   files. That is an appearance change to windows no golden has ever covered, so
%   capture BEFORE the rewrite and diff the .txt files after:
%
%       captureSimGoldens('Test/GUI/evidence/before_F2')
%       ... rewrite ...
%       captureSimGoldens('Test/GUI/evidence/after_F2')
%       diff -ru Test/GUI/evidence/before_F2 Test/GUI/evidence/after_F2
%
%   The windows are GUIDE singletons and share Tag='Simu', so each is deleted
%   before the next opens -- otherwise the second call raises the first window
%   and captures it twice under two different names.
%
%   See also: captureFigure, captureGoldens, Test/GUI/tSimWindows.m

    arguments
        outDir    {mustBeTextScalar}
        modelName {mustBeTextScalar} = 'charmed'
    end

    % Name, not Tag: all five carry Tag='Simu', and three are named after their
    % .fig rather than after the window.
    windows = { 'Sim_Single_Voxel_Curve_GUI',       'Single Voxel Curve'
                'Sim_Sensitivity_Analysis_GUI',     'Sensitivity Analysis'
                'Sim_Multi_Voxel_Distribution_GUI', 'Multi Voxel Distribution'
                'Sim_Optimize_Protocol_GUI',        'SimOptProt'
                'Sim_MonteCarlo_Diffusion_GUI',     'SimMCdiff' };

    if ~exist(outDir, 'dir'); mkdir(outDir); end
    model = feval(modelName);
    fprintf('Capturing %s Sim windows into %s\n', modelName, outDir);

    for k = 1:size(windows, 1)
        delete(findall(groot, 'Tag', 'Simu'));
        % The Update callbacks read the model back out of the shared store.
        setappdata(0, 'Model', model);
        try
            feval(windows{k,1}, model);
        catch ME
            fprintf('  %-34s DID NOT OPEN: %s\n', windows{k,1}, ME.message);
            continue
        end
        drawnow; pause(0.5); drawnow;

        fig = findall(groot, 'Type', 'figure', 'Name', windows{k,2});
        if isempty(fig)
            fprintf('  %-34s no figure named ''%s''\n', windows{k,1}, windows{k,2});
            continue
        end
        label = sprintf('%s_%s', modelName, matlab.lang.makeValidName(windows{k,2}));
        captureFigure(outDir, label, fig(1));

        defects = geomAudit(fig(1));
        fprintf('  %-34s %d layout defect(s)\n', windows{k,2}, numel(defects));
    end

    delete(findall(groot, 'Tag', 'Simu'));
end
