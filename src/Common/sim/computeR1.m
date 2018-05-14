function R1f = computeR1(Param, R1obs)

kf  = Param.kf;
F  = Param.F;
R1r = Param.R1r;

R1f = R1obs - kf*(R1r - R1obs) / (R1r - R1obs + kf/F);

end