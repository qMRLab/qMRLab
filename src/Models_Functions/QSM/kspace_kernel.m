function [kernel] = kspace_kernel(FOV,N)

% FOV : field of view in x, y, and z directions
% N   : no of samples in kx, ky, kz
% center : center index of the k-space (cx,cy,cx)

center = N/2 + 1;

kx = 1:N(1);
ky = 1:N(2);
kz = 1:N(3);

kx = kx - center(1);
ky = ky - center(2);
kz = kz - center(3);


% determine the step sizes delta_kx, delta_ky, delta_kz in k-space
delta_kx = 1/FOV(1);
delta_ky = 1/FOV(2);
delta_kz = 1/FOV(3);


kx = kx * delta_kx;
ky = ky * delta_ky;
kz = kz * delta_kz;

kx = reshape(kx,[length(kx),1,1]);
ky = reshape(ky,[1,length(ky),1]);
kz = reshape(kz,[1,1,length(kz)]);

kx = repmat(kx,[1,N(2),N(3)]);
ky = repmat(ky,[N(1),1,N(3)]);
kz = repmat(kz,[N(1),N(2),1]);


k2 = kx.^2 + ky.^2 + kz.^2;
k2(k2==0) = eps;

kernel = 1/3 - kz.^2 ./ k2;    

DC = (kx==0) & (ky==0) & (kz==0);
kernel(DC==1) = 0;

end
