hold off 
M = [0;0;1];
alpha = deg2rad(30);
B1 = 1;
Rfph = 0;


tmp = x_rot(-2*alpha*B1)*y_rot(-2*alpha*B1)*x_rot(2*alpha*B1)*y_rot(2*alpha*B1)*th_rot(alpha, 0)*M