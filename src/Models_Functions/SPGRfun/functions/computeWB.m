function WB = computeWB(w1, Delta, T2r, lineshape, onres)

if (~exist('onres','var') || isempty(onres))
    onres = 1;   % by default, extrapolate near resonance
end

% One-entry memo for the lineshape value.
%
% G is a pure function of (Delta, T2r, lineshape, onres). Under lsqcurvefit the
% Jacobian is built by finite differences that perturb one parameter at a time,
% so most consecutive calls within an iteration leave T2r untouched and would
% otherwise recompute an identical G -- which for the SuperLorentzian means an
% adaptive numerical integration per offset, the single largest cost in the fit.
%
% Delta already carries the per-voxel B0 shift (SPGR_fit does
% Prot.Offsets = Prot.Offsets + FitOpt.B0), so a voxel with a different B0 keys
% differently and correctly misses. Comparisons are ordered cheapest-first so a
% miss short-circuits before reaching the vector compare.
%
% Cache G, NOT WB: w1 derives from the B1-scaled angles and varies per voxel
% while not appearing in the key, so a cached WB would leak one voxel's B1 into
% another's fit.
persistent kDelta kT2r kShape kOnres kG

if ~isempty(kG) && isequal(T2r, kT2r) && isequal(onres, kOnres) ...
        && isequal(lineshape, kShape) && isequal(Delta, kDelta)
    G = kG;
else
    G = computeG(Delta, T2r, lineshape, onres);
    kDelta = Delta; kT2r = T2r; kShape = lineshape; kOnres = onres; kG = G;
end

WB = G .* pi .* w1.^2;

end