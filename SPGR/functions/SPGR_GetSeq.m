function [Angle,Delta] = SPGR_GetSeq( angle, delta )

Angle = zeros(length(delta)*length(angle),1);
Delta = Angle;

kk=1;
for ii = 1:length(angle)
    for jj = 1:length(delta)
        Angle(kk) = angle(ii);
        Delta(kk) = delta(jj);
        kk = kk+1;
    end
end

end