function g_Super = superlorentzianLineshape(delta, T2r, onres)

% g_Super: returns the lineshape amplitude of a SuperLorentzian pool of given T2r,
% at the indicated frequency
% scaled such that W = pi*(omega1^2)*g_Super

if (~exist('onres','var') || isempty(onres))
    onres = 1;   % by default, extrapolate near resonance
end

delta = delta(:);

% Extrapolation near on-res to avoid singularity
if onres
    near = delta <= 1500;
    delta(near) = 0.00016*delta(near).^2 + 1140;
end

if moxunit_util_platform_is_octave
    % Octave's quad has no array-valued mode; integrate each offset in turn.
    g_Super = zeros(numel(delta),1);
    for ii = 1:numel(delta)
        fun = @(u) sqrt(2/pi) .* (T2r./abs(3*u.^2-1)) .* ...
            exp(-2*((2*pi .* delta(ii) .* T2r)./(3*u.^2-1)).^2);
        g_Super(ii) = quad(fun, 0, 1);
    end
else
    % One adaptive integration covering every offset, rather than one per
    % offset. The integrand is the same; 'ArrayValued' returns a vector in
    % delta for each scalar u and drives a single refinement for the whole
    % set. That trades N adaptive drivers for one, which is what costs here --
    % this function is called on every model evaluation inside lsqcurvefit.
    %
    % Because the refinement is now shared, it is governed by the hardest
    % offset in the set rather than each offset independently, so values can
    % differ from the per-offset form within the integrator's tolerance.
    fun = @(u) sqrt(2/pi) .* (T2r./abs(3*u.^2-1)) .* ...
        exp(-2*((2*pi .* delta .* T2r)./(3*u.^2-1)).^2);
    g_Super = integral(fun, 0, 1, 'ArrayValued', true);
end

