hold off 
M = [0;0;1];
alpha = deg2rad(1:180);
B1 = 1;
Rfph = 0;

for ii=1:180
     tmp = y_rot(2*alpha(ii)*B1)*(th_rot(alpha(ii).*B1, 0)*M);
     Msig(ii) = norm(tmp(1:2));
end

plot(alpha,Msig)

hold on 

for ii=1:180
     tmp =th_rot(alpha(ii).*B1, 0)*M;
     Msig(ii) = norm(tmp(1:2));
end

plot(alpha,Msig, 'r')