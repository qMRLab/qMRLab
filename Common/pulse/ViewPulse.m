function ViewPulse(Pulse, field)

for ii = 1:length(Pulse)
    Trf = Pulse(ii).Trf;
    t = 0:Trf/1000:Trf;
    y = Pulse(ii).(field)(t);
    plot(t*1000,y); hold on;
    leg{ii} = [Pulse(ii).shape];
end

legend(leg);
xlabel('Time (ms)');
ylabel(field);

end