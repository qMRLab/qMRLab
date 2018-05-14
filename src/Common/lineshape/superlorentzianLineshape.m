function g_Super = superlorentzianLineshape(delta, T2r, onres)

% g_Super: returns the lineshape amplitude of a SuperLorentzian pool of given T2r,
% at the indicated frequency
% scaled such that W = pi*(omega1^2)*g_Super

g_Super = zeros(length(delta),1);

if (~exist('onres','var') || isempty(onres))
    onres = 1;   % by default, extrapolate near resonance
end

for ii = 1:length(delta)
    
    % Extrapolation near on-res to avoid singularity
    if (onres && (delta(ii) <= 1500) )    
        delta(ii) = 0.00016*delta(ii).^2 + 1140;
    end
        
    fun = @(u) sqrt(2/pi) .* (T2r./abs(3*u.^2-1)) .* ...
        exp(-2*((2*pi .* delta(ii) .* T2r)./(3*u.^2-1)).^2);
    
    if moxunit_util_platform_is_octave
        g_Super(ii) = quad(fun, 0, 1);
    else
        g_Super(ii) = integral(fun, 0, 1);
    end
end

