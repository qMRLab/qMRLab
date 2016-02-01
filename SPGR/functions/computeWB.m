function WB = computeWB(w1, Delta, T2r, lineshape)

G = computeG(Delta, T2r, lineshape);
WB = G .* pi .* w1.^2;

end