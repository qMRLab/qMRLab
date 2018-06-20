function [Alpha, Trf] = bSSFP_GetSeq( VaryAlpha, FixTrf, VaryTrf, FixAlpha )

Alpha =  zeros(length(VaryTrf)+length(VaryAlpha), 1);
Trf   =  Alpha;

kk=1;
for ii = 1:length(VaryAlpha)
    Alpha(kk) = VaryAlpha(ii);
    Trf(kk) = FixTrf;
    kk = kk+1;
end

for jj = 1:length(VaryTrf)
    Alpha(kk) = FixAlpha;
    Trf(kk) = VaryTrf(jj);
    kk = kk+1;
end

end