function Dh_perp = scd_model_timedependence(Dextinf,A,Delta,delta)
% Fieremans, E., Burcaw, L.M., Lee, H.-H., Lemberskiy, G., Veraart, J., Novikov, D.S., 2016. In vivo observation and biophysical interpretation of time-dependent diffusion in human white matter. Neuroimage 129, 414?427.
% BURCAW_2015_longpulse
if A % if non-zero length of coherence
    t = Delta(:);
    delta = delta(:);
    term1 = Dextinf;
    term2 = (A./(2*delta.^2.*(t-delta/3)));
    term3 = (t.^2.*log((t.^2-delta.^2)./t.^2) + delta.^2.*log((t.^2-delta.^2)./delta.^2) + 2*t.*delta.*log((t+delta)./(t-delta)));
    Dh_perp = term1+term2.*term3;
else
    Dh_perp = Dextinf;
end

