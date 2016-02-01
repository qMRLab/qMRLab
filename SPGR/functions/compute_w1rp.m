function [w1rp, Tau] = compute_w1rp(Pulse)
%compute_w1rms Compute the equivalent power of a rectangular pulse of
%duration of the FWHM of the shaped pulse

w1rp = zeros(length(Pulse),1);
Tau = w1rp;

for ii = 1:length(Pulse)
        
    Trf = Pulse(ii).Trf;
    omega2 = Pulse(ii).omega2;
    int = integral(omega2, 0, Trf,'ArrayValued',true);
    
    if strcmp(Pulse(ii).shape,'hard')
        Tau(ii) = Trf;
    else
        x = 0:Trf/1000:Trf;
        y = omega2(x);
        Tau(ii) = fwhm(x,y);
    end
    w1rp(ii) = sqrt( int / Tau );
end

end

