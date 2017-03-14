function SPGR_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults)

semilogx(Prot.Offsets, MTdata,'bx'); hold on;

if (Sim.Opt.AddNoise)
    semilogx(Prot.Offsets, MTnoise,'bo','MarkerSize',8);
end

semilogx(SimCurveResults.Offsets, SimCurveResults.curve, 'r');

leg = {};
leg{1} = 'Raw data';

if (Sim.Opt.AddNoise)
   leg{2} = 'Noisy data';
end

leg{end+1} = 'Fitted curve';
hleg = legend(leg);
set(hleg,'location','best','FontSize',8);
legend('boxoff');
xlabel('Offets (Hz)','FontWeight','bold','FontSize',10);
ylabel('|Mz|','FontWeight','bold','FontSize',10);