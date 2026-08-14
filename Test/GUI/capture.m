function capture(w, h, name)
    qMRLab(inversion_recovery); drawnow; pause(1.5);
    fig = findall(groot,'Type','figure','Name','qMRLab');
    fig.Position(3:4) = [w h]; drawnow; pause(1.0); drawnow;
    out = fullfile(pwd,'Test','GUI','shots'); if ~isfolder(out), mkdir(out); end
    exportapp(fig, fullfile(out,[name '.png']));
    fprintf('captured %s at %dx%d\n', name, w, h);
end
