function [Sr,Sf] = computeSr(Param, Prot)
%Simulated saturation effect of inversion pulse on restricted and free pools

Param.G    = computeG(0, Param.T2r, Param.lineshape);
Trf        = Prot.InvPulse.Trf;
PulseShape = Prot.InvPulse.shape;
InvPulse   = GetPulse(180,0,Trf,PulseShape);
M0 = [0 0 Param.M0f Param.M0r];

% Inversion pulse
[~, M_temp] = ode23(@(t,M) Bloch(t, M, Param, InvPulse), [0 Trf], M0);
Sr = M_temp(end,4)/Param.M0r;
Sf = M_temp(end,3)/Param.M0f;