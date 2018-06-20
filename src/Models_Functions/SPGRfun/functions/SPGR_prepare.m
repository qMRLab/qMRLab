function [Angles, Offsets, w1cw, w1rms, w1rp, Tau] = SPGR_prepare( Prot )

Angles  = Prot.Angles;
Offsets = Prot.Offsets;
w1cw  = zeros(length(Angles),1);
w1rms = w1cw;
w1rp  = w1cw;
Tau   = w1cw;

for ii = 1:length(Angles)
    Pulse = GetPulse(Angles(ii), Offsets(ii), Prot.Tm, Prot.MTpulse.shape, Prot.MTpulse.opt);
    w1cw(ii) = compute_w1cw(Prot.TR, Pulse);
    w1rms(ii) = compute_w1rms(Pulse);
    [w1rp(ii), Tau(ii)] = compute_w1rp(Pulse);
end
        
end