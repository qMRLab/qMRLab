function ans=erfi(x)
% %erfi(x). The Imaginary error function, as it is defined in Mathematica
% %erfi(z)==erf(iz)/i (z could be complex) using 
% %the incomplete gamma function in matlab: gammainc
% %Using "@": erfi = @(x) real(-sqrt(-1).*sign(x).*gammainc(-x.^2,1/2))
% %Note: limit(x->0) erfi(x)/x -> 2/sqrt(pi)
%
% %Example 1: 
% x=linspace(0.001,6,100);
% y=exp(-x.^2).*erfi(x)./2./x;
% figure(1), clf;plot(x,y*sqrt(pi))
%
% %Example 2: 
% [x,y]=meshgrid(linspace(-3,3,180),linspace(-3,3,180));
% z=x+i*y;
% figure(1), clf;contourf(x,y,log(erfi(z)))
% axis equal;axis off
xc=5.7;%cut for asymptotic approximation (when x is real)
ans=~isreal(x).*(-(sqrt(-x.^2)./(x+isreal(x))).*gammainc(-x.^2,1/2))+...
    isreal(x).*real(-sqrt(-1).*sign(x).*((x<xc).*gammainc(-x.^2,1/2))+...
    (x>=xc).*exp(x.^2)./x/sqrt(pi));
