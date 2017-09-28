function SIRFSE_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults)

if ~isempty(MTdata)
    plot3(Prot.ti, Prot.td, MTdata, 'bx', 'MarkerSize', 8); hold on;
else
    MTdata=1;
end
if (Sim.Opt.AddNoise)
    plot3(Prot.ti, Prot.td, MTnoise,'bo','MarkerSize',8);
    plot3(SimCurveResults.ti, SimCurveResults.td, SimCurveResults.curve, 'r');
    hleg = legend('Raw data', 'Noisy data', 'Fitted curve');
else
    plot3(SimCurveResults.ti, SimCurveResults.td, SimCurveResults.curve, 'r');
    hleg = legend('Raw data', 'Fitted curve');
end

xlabel('Inversion time (s)','FontWeight','bold','FontSize',10);
ylabel('Delay time (s)','FontWeight','bold','FontSize',10);
zlabel('|Mz|','FontWeight','bold','FontSize',10);
zlim([0, max(1e-10,1.1*max(MTdata))]);
xlim([SimCurveResults.ti(1) SimCurveResults.ti(end)]);
set(hleg,'Location','SouthWest','FontSize',8);
legend('boxoff');
axes1 = gca;
view(axes1,[0 0]);
set(axes1, 'XScale', 'log')
hold off;