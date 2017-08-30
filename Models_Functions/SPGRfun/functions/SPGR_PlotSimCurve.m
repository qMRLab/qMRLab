function SPGR_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults)

semilogx(Prot.Offsets, MTdata,'bx'); hold on;

if (Sim.Opt.AddNoise)
    semilogx(Prot.Offsets, MTnoise,'bo','MarkerSize',8);
end

semilogx(SimCurveResults.Offsets, SimCurveResults.curve);

leg = {};
leg{1} = 'Raw data';

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
set(hleg,'location','best','FontSize',8);
legend('boxoff');
xlabel('Offets (Hz)','FontWeight','bold','FontSize',10);
ylabel('|Mz|','FontWeight','bold','FontSize',10);