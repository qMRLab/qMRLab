function amp = computeAmp( alpha, Pulse )
%computeAmp Compute pulse amplitude given flip angle in degrees
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% ----------------------------------------------------------------------------------------------------


gamma = 2*pi*42576;
nA = length(alpha);
nP = length(Pulse);

amp = zeros(nA,nP);
for ii = 1:nA
    for jj = 1:nP
        Trf = Pulse(jj).Trf;
        int = integral(Pulse(jj).b1, 0, Trf,'ArrayValued',true);
        amp(ii,jj) = 2*pi*alpha(ii) / ( 360 * gamma * int );
    end
end

end

