function Sf = computeSf(T2f, Pulse)
%Simulated saturation effect of MT pulse on free pool

nPulse = length(Pulse);
Sf = zeros(nPulse,1);
M0 = [0 0 1];

for kk=1:nPulse
    MTpulse = Pulse(kk);
    [~, M_temp] = ode23(@(t,M) BlochNoMT(t, M, T2f, MTpulse), [0 MTpulse.Trf], M0);
    Sf(kk) = M_temp(end,3);
end

end
