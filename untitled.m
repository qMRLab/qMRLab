close all
clear all
clc

rf = msinc(256,2);

rf = rf*(deg2rad(60))/sum(rf);
plot(rf);

x = [-64:64]/4;

[a b] = abr(rf, x)

plot(a)
title("Alpha:");

plot(b)
title("Beta:");

mxy_ex = ab2ex(a,b);
plot(x,abs(mxy_ex));
title("Excitation Profile");

hold on


rf = msinc(256,2);

rf = rf*(deg2rad(120))/sum(rf);

x = [-64:64]/4;

[a b] = abr(rf, x)

mxy_ex = ab2ex(a,b);
plot(x,abs(mxy_ex));
title("Excitation Profile");


