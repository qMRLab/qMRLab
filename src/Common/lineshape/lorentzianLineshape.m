function g_lorentz = lorentzianLineshape(delta, T_2r)

% g_lorentz: returns the lineshape amplitude of a Lorentzian pool of given T2r
% at the indicated frequency
% scaled such that W = pi*(omega1^2)*g_lorentz

g_lorentz = (T_2r ./ pi)./(1+(2*pi*delta .* T_2r).^2);
