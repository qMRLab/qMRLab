function SPGR_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults)

leg = {};
if ~isempty(MTdata)
    semilogx(Prot.Offsets, MTdata,'bx'); hold on;
    leg{1} = 'Raw data';
end
if (Sim.Opt.AddNoise)
    semilogx(Prot.Offsets, MTnoise,'bo','MarkerSize',8);
end

semilogx(SimCurveResults.Offsets, SimCurveResults.curve);


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
hleg = legend(leg);
set(hleg,'FontSize',8)
if ~moxunit_util_platform_is_octave
    set(hleg,'location','best');
    legend('boxoff');
end
xlabel('Offets (Hz)','FontWeight','bold','FontSize',10);
ylabel('|Mz|','FontWeight','bold','FontSize',10);