function ls = gaussLineShape(t2b,delta)
% t2b is t2 of Gaussian Function
% delta is in Hz


expval = ((2*pi*delta * t2b)^2) /2;

ls = sqrt(pi/2)* t2b* exp(-expval);
