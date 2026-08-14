function probeTheme()
    out = fullfile(pwd,'Test','GUI','shots'); if ~isfolder(out), mkdir(out); end
    qMRLab(inversion_recovery); drawnow; pause(1.5);
    fig = findall(groot,'Type','figure','Name','qMRLab');

    n = numel(findall(fig,'-property','BackgroundColor'));
    fprintf('components with BackgroundColor: %d\n', n);
    % how many carry a NON-factory colour (which native Theme will refuse to touch)
    explicit = 0;
    for h = findall(fig,'-property','BackgroundColor')'
        try
            if ~isequal(round(h.BackgroundColor,3), [0.94 0.94 0.94]), explicit = explicit + 1; end
        catch, end
    end
    fprintf('carrying a non-factory BackgroundColor: %d\n', explicit);

    fprintf('figure Theme before: %s\n', class(fig.Theme));
    fig.Theme = 'dark'; drawnow; pause(1.2); drawnow;
    exportapp(fig, fullfile(out,'theme_dark.png'));
    fprintf('after Theme=dark, figure Color = %s\n', mat2str(round(fig.Color,3)));
    p = findall(fig,'Tag','FitDataPanel');
    fprintf('FitDataPanel BackgroundColor = %s\n', mat2str(round(p.BackgroundColor,3)));
end
