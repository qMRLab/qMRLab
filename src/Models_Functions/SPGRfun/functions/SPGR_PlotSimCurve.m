function SPGR_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults)

leg = {};
if ~isempty(MTdata)
    semilogx(Prot.Offsets, MTdata,'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k'); hold on;
    leg{1} = 'Raw data';
end
if (Sim.Opt.AddNoise)
    semilogx(Prot.Offsets, MTnoise,'bo','MarkerSize',8);
end

% Pretify
set(gca, 'ColorOrder', [0.9290 0.6940 0.1250; 0 0.4470 0.7410; .8500 0.3250 0.0980]);

if min(Prot.Offsets)>=300 % Below 300, the simulated curve calculation changes, giving a "kink" to the curve
    semilogx(SimCurveResults.Offsets(SimCurveResults.Offsets>300), SimCurveResults.curve(find(SimCurveResults.Offsets>300),:), '--', 'LineWidth', 2);
else
    semilogx(SimCurveResults.Offsets, SimCurveResults.curve, '--', 'LineWidth', 2);
end



if (Sim.Opt.AddNoise)
   leg{2} = 'Noisy data';
end

nAngles  = size(SimCurveResults.curve,2);
nOffsets = length(Prot.Offsets)/nAngles;
uniqueAngles = sort(unique(Prot.Angles));
for i = 1:nAngles
    leg{end+1} = sprintf('Fitted curve (angle = %0.0f)', uniqueAngles(i));
end

if ~moxunit_util_platform_is_octave
    hleg = legend(leg, 'FontSize', 12);
    legend('boxoff')
    set(hleg,'Location', 'best')
else
    hleg = legend(leg);
    set(hleg,'FontSize',8)
    set(hleg,'location', 'southeast')    
end
xlabel('Offset (Hz)','FontWeight','bold','FontSize',10);
ylabel('|Mz|','FontWeight','bold','FontSize',10);

set(gca, 'XScale', 'log');
