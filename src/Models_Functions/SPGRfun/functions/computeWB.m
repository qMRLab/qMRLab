function WB = computeWB(w1, Delta, T2r, lineshape, onres)

if (~exist('onres','var') || isempty(onres))
    onres = 1;   % by default, extrapolate near resonance
end
G = computeG(Delta, T2r, lineshape, onres);
WB = G .* pi .* w1.^2;

end