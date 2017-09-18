function W = computeW(G, Pulse)
% Compute Mean saturation rate <W(delta,alpha)> for given G(delta)
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% ----------------------------------------------------------------------------------------------------


W = zeros(length(Pulse),1);

for ii = 1:length(Pulse)
    omega2 = Pulse(ii).omega2;
    Trf = Pulse(ii).Trf;
    if moxunit_util_platform_is_octave
        int = quadv(omega2, 0, Trf);
    else
        int = integral(omega2, 0, Trf, 'ArrayValued', true);
    end
    W(ii) = G * pi/Trf * int;
end