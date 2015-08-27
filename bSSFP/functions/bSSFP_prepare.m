function [alpha, Trf, TR, W] = bSSFP_prepare(Prot,FitOpt)

alpha = Prot.alpha;
Trf = Prot.Trf;
W = zeros(length(Prot.alpha),1);

if (Prot.FixTR)
    TR = Prot.TR * ones(length(alpha),1);
else
    TR = Prot.Td + Trf;
end

for ii = 1:length(alpha)
    Pulse = GetPulse(alpha(ii),0,Trf(ii),Prot.Pulse.shape);
    W(ii) = computeW(FitOpt.G, Pulse);
end

end