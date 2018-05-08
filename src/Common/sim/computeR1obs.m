function R1obs = computeR1obs(Param)

kf  = Param.kf;
kr  = Param.kr;
R1f = Param.R1f;
R1r = Param.R1r;

R1obs = 1/2*( kf + kr + R1f + R1r - sqrt( (kf - kr + R1f - R1r)^2 + 4*kf*kr ) );

end