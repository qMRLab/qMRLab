function f4 = superlor6(t2b,delta)
% function [ctheta,f1,f3,f4,f5] =superlor_test_theta(t2b);
% t2b is t2 of Gaussian Function
% delta is sweep width
% Uses gaussian kernal Scott Swanson University of Michigan 
 
 
[d1 d2]=size(delta);
stp=1/1000;
ctheta=0:stp:1; %create ctheta
[t1 t2]=size(ctheta);
ctheta=repmat(ctheta',[1 d2]); %make 2d
delta1=repmat(delta,[t2 1]);
 
 
f1=t2b*sqrt(2/pi)*(stp).*(abs(-1+3.*(ctheta).^2)).^(-1); %calculate line intensity
f2=exp(-2*((delta1*t2b).^2).*((3*(ctheta).^2-1).^(-2))); %calculate line shapes
f3=f1.*f2; % intensity times shape
f4=sum(f3,1); % sum over intensities this is the sl line
end