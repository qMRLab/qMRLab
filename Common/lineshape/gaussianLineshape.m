function g_gauss = gaussianLineshape(delta, T_2r)

% g_gauss: returns the lineshape amplitude of a Gaussian pool of given T2r,
% at the indicated frequency
% scaled such that W = pi*(omega1^2)*g_gauss

g_gauss = sqrt(1/(2*pi)) .* T_2r .* exp(-((2*pi.*delta .* T_2r).^2)./2);
