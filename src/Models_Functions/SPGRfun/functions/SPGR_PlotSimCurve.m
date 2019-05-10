function SPGR_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults)

leg = {};
if ~isempty(MTdata)
    semilogx(Prot.Offsets, MTdata,'kx', 'MarkerSize', 8); hold on;
    leg{1} = 'Raw data';
end
if (Sim.Opt.AddNoise)
    semilogx(Prot.Offsets, MTnoise,'bo','MarkerSize',8);
end

semilogx(SimCurveResults.Offsets, SimCurveResults.curve, 'LineWidth', 2);


if (Sim.Opt.AddNoise)
   leg{2} = 'Noisy data';
end

nAngles  = size(SimCurveResults.curve,2);
nOffsets = length(Prot.Offsets)/nAngles;
for i = 1:nAngles
    if Prot.Angles(1) == Prot.Angles(2)
        leg{end+1} = sprintf('Fitted curve (angle = %0.0f)',Prot.Angles(nOffsets*i));
    else
        leg{end+1} = sprintf('Fitted curve (angle = %0.0f)',Prot.Angles(i));
    end        
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
