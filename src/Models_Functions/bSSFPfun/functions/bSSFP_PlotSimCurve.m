function bSSFP_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults, axe)

FixAlpha = find(diff(Prot.alpha)==0);
FixTrf = find(diff(Prot.Trf)==0);

if (~isempty(FixTrf))
    axes(axe(1));
    ii = FixTrf(1);
    jj = FixTrf(end)+1;
    if ~isempty(MTdata)
        plot(Prot.alpha(ii:jj), MTdata(ii:jj),'x'); hold on;
    end
    plot(SimCurveResults.alpha, SimCurveResults.alphaCurve,'r');
    if (Sim.Opt.AddNoise)
        plot(Prot.alpha(ii:jj), MTnoise(ii:jj),'o');
    end
    hold off;
    xlabel('Flip angle \alpha (deg)','FontWeight','bold','FontSize',10);
    ylabel('|Mxy|','FontWeight','bold','FontSize',10);
end


if (~isempty(FixAlpha))
    axes(axe(2));
    ii = FixAlpha(1);
    jj = FixAlpha(end)+1;
    if ~isempty(MTdata)
        plot(Prot.Trf(ii:jj)*1000, MTdata(ii:jj),'x'); hold on
    end
        plot(SimCurveResults.Trf*1000, SimCurveResults.TrfCurve,'r');
    if (Sim.Opt.AddNoise)
        plot(Prot.Trf(ii:jj)*1000, MTnoise(ii:jj),'o');
    end
    hold off;
    xlabel('RF pulse duration Trf (ms)','FontWeight','bold','FontSize',10);
    ylabel('|Mxy|','FontWeight','bold','FontSize',10);
end

if (Sim.Opt.AddNoise)
    hleg = legend('Raw data', 'Fitted curve', 'Noisy data');
else
    hleg = legend('Raw data', 'Fitted curve');
end
if moxunit_util_platform_is_octave
    set(hleg,'FontSize',8)
else
    set(hleg,'location','best','FontSize',8);
end
legend('boxoff');