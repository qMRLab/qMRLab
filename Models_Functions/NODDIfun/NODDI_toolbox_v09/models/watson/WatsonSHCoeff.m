function [C, D] = WatsonSHCoeff(k)
% function [C, D] = WatsonSHCoeff(k)
% Computes the spherical harmonic (SH) coefficients of the Watson's
% distribution with the concentration parameter k (kappa) up to the 12th order
% and the derivatives if requested.
%
% Truncating at the 12th order gives good approximation for kappa up to 64.
%
% INPUTS:
%
% k should be an array of positive numbers, specifying a set of
% concentration parameters for the Watson's distribution.
%
% OUTPUTS:
%
% C will be a 2-D array and each row contains the SH coefficients of the
% orders 0, 2, 4, ..., to 2n for the parameter in the corresponding row in
% k.
%
% Note that the SH coefficients of the odd orders are always zero.
%
% D will be the 1st order derivative of C.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

large = find(k>30);
exact = find(k>0.1);
approx = find(k<=0.1);
% Necessary to make matlab happy when k is a single value
exact = exact(:);
approx = approx(:);
large = large(:);

% The maximum order of SH coefficients (2n)
n = 6;

% Computing the SH coefficients
C = zeros(length(k),n+1);

% 0th order is a constant
C(:,1) = 2*sqrt(pi);

% Precompute the special function values
sk = sqrt(k(exact));
sk2 = sk.*k(exact);
sk3 = sk2.*k(exact);
sk4 = sk3.*k(exact);
sk5 = sk4.*k(exact);
sk6 = sk5.*k(exact);
sk7 = sk6.*k(exact);
k2 = k.^2;
k3 = k2.*k;
k4 = k3.*k;
k5 = k4.*k;
k6 = k5.*k;
k7 = k6.*k;

erfik = erfi(sk);
ierfik = 1./erfik;
ek = exp(k(exact));
dawsonk = 0.5*sqrt(pi)*erfik./ek;

% for large enough kappa
C(exact,2) = 3*sk - (3 + 2*k(exact)).*dawsonk;
C(exact,2) = sqrt(5)*C(exact,2).*ek;
C(exact,2) = C(exact,2).*ierfik./k(exact);

C(exact,3) = (105 + 60*k(exact) + 12*k2(exact)).*dawsonk;
C(exact,3) = C(exact,3) -105*sk + 10*sk2;
C(exact,3) = .375*C(exact,3).*ek./k2(exact);
C(exact,3) = C(exact,3).*ierfik;

C(exact,4) = -3465 - 1890*k(exact) - 420*k2(exact) - 40*k3(exact);
C(exact,4) = C(exact,4).*dawsonk;
C(exact,4) = C(exact,4) + 3465*sk - 420*sk2 + 84*sk3;
C(exact,4) = C(exact,4)*sqrt(13*pi)/64./k3(exact);
C(exact,4) = C(exact,4)./dawsonk;

C(exact,5) = 675675 + 360360*k(exact) + 83160*k2(exact) + 10080*k3(exact) + 560*k4(exact);
C(exact,5) = C(exact,5).*dawsonk;
C(exact,5) = C(exact,5) - 675675*sk + 90090*sk2 - 23100*sk3 + 744*sk4;
C(exact,5) = sqrt(17)*C(exact,5).*ek;
C(exact,5) = C(exact,5)/512./k4(exact);
C(exact,5) = C(exact,5).*ierfik;

C(exact,6) = -43648605 - 22972950*k(exact) - 5405400*k2(exact) - 720720*k3(exact) - 55440*k4(exact) - 2016*k5(exact);
C(exact,6) = C(exact,6).*dawsonk;
C(exact,6) = C(exact,6) + 43648605*sk - 6126120*sk2 + 1729728*sk3 - 82368*sk4 + 5104*sk5;
C(exact,6) = sqrt(21*pi)*C(exact,6)/4096./k5(exact);
C(exact,6) = C(exact,6)./dawsonk;

C(exact,7) = 7027425405 + 3666482820*k(exact) + 872972100*k2(exact) + 122522400*k3(exact)  + 10810800*k4(exact) + 576576*k5(exact) + 14784*k6(exact);
C(exact,7) = C(exact,7).*dawsonk;
C(exact,7) = C(exact,7) - 7027425405*sk + 1018467450*sk2 - 302630328*sk3 + 17153136*sk4 - 1553552*sk5 + 25376*sk6;
C(exact,7) = 5*C(exact,7).*ek;
C(exact,7) = C(exact,7)/16384./k6(exact);
C(exact,7) = C(exact,7).*ierfik;

% for very large kappa
if size(large,1) > 0
  lnkd = log(k(large)) - log(30);
  lnkd2 = lnkd.*lnkd;
  lnkd3 = lnkd2.*lnkd;
  lnkd4 = lnkd3.*lnkd;
  lnkd5 = lnkd4.*lnkd;
  lnkd6 = lnkd5.*lnkd;
  C(large,2) = 7.52308 + 0.411538*lnkd - 0.214588*lnkd2 + 0.0784091*lnkd3 - 0.023981*lnkd4 + 0.00731537*lnkd5 - 0.0026467*lnkd6;
  C(large,3) = 8.93718 + 1.62147*lnkd - 0.733421*lnkd2 + 0.191568*lnkd3 - 0.0202906*lnkd4 - 0.00779095*lnkd5 + 0.00574847*lnkd6;
  C(large,4) = 8.87905 + 3.35689*lnkd - 1.15935*lnkd2 + 0.0673053*lnkd3 + 0.121857*lnkd4 - 0.066642*lnkd5 + 0.0180215*lnkd6;
  C(large,5) = 7.84352 + 5.03178*lnkd - 1.0193*lnkd2 - 0.426362*lnkd3 + 0.328816*lnkd4 - 0.0688176*lnkd5 - 0.0229398*lnkd6;
  C(large,6) = 6.30113 + 6.09914*lnkd - 0.16088*lnkd2 - 1.05578*lnkd3 + 0.338069*lnkd4 + 0.0937157*lnkd5 - 0.106935*lnkd6;
  C(large,7) = 4.65678 + 6.30069*lnkd + 1.13754*lnkd2 - 1.38393*lnkd3 - 0.0134758*lnkd4 + 0.331686*lnkd5 - 0.105954*lnkd6;
end

% for small kappa
C(approx,2) = 4/3*k(approx) + 8/63*k2(approx);
C(approx,2) = C(approx,2)*sqrt(pi/5);

C(approx,3) = 8/21*k2(approx) + 32/693*k3(approx);
C(approx,3) = C(approx,3)*(sqrt(pi)*0.2);

C(approx,4) = 16/693*k3(approx) + 32/10395*k4(approx);
C(approx,4) = C(approx,4)*sqrt(pi/13);

C(approx,5) = 32/19305*k4(approx);
C(approx,5) = C(approx,5)*sqrt(pi/17);

C(approx,6) = 64*sqrt(pi/21)*k5(approx)/692835;

C(approx,7) = 128*sqrt(pi)*k6(approx)/152108775;

if nargout == 1
	return;
end

% Computing the derivatives
dawsonk2 = dawsonk.^2;
idawsonk2 = 1./dawsonk2;

D = zeros(length(k),n+1);
D(:,1) = 0.0;

% exact
D(exact,2) = -k(exact) + (2*sk2 -sk).*dawsonk + 2*dawsonk2;
D(exact,2) = (.75*sqrt(5*pi))*D(exact,2)./k2(exact).*idawsonk2;

D(exact,3) = 21*k(exact) - 2*k2(exact);
D(exact,3) = D(exact,3) + (63*sk -44*sk2 + 4*sk3).*dawsonk;
D(exact,3) = D(exact,3) - (84 + 24*k(exact)).*dawsonk2;
D(exact,3) = D(exact,3)*(15*sqrt(pi)/32)./k3(exact).*idawsonk2;

D(exact,4) = -165*k(exact) + 20*k2(exact) - 4*k3(exact);
D(exact,4) = D(exact,4) + (-825*sk + 390*sk2 - 44*sk3 + 8*sk4).*dawsonk;
D(exact,4) = D(exact,4) + (990 + 360*k(exact) + 40*k2(exact)).*dawsonk2;
D(exact,4) = D(exact,4)*(21*sqrt(13*pi)/128)./k4(exact).*idawsonk2;

D(exact,5) = 225225*k(exact) - 30030*k2(exact) + 7700*k3(exact) - 248*k4(exact);
D(exact,5) = D(exact,5) + (1576575*sk - 600600*sk2 + 83160*sk3 - 15648*sk4 + 496*sk5).*dawsonk;
D(exact,5) = D(exact,5) - (1801800 + 720720*k(exact) + 110880*k2(exact) + 6720*k3(exact)).*dawsonk2;
D(exact,5) = D(exact,5)*(3*sqrt(17*pi)/2048)./k5(exact).*idawsonk2;

D(exact,6) = -3968055*k(exact) + 556920*k2(exact) - 157248*k3(exact) + 7488*k4(exact) - 464*k5(exact);
D(exact,6) = D(exact,6) + (-35712495*sk + 11834550*sk2 - 1900090*sk3 + 336960*sk4 - 15440*sk5 + 928*sk6).*dawsonk;
D(exact,6) = D(exact,6) + (39680550 + 16707600*k(exact) + 2948400*k2(exact) + 262080*k3(exact) + 10080*k4(exact)).*dawsonk2;
D(exact,6) = D(exact,6)*(11*sqrt(21*pi)/8192)./k6(exact).*idawsonk2;

D(exact,7) = 540571185*k(exact) - 78343650*k2(exact) + 23279256*k3(exact) - 1319472*k4(exact) + 119504*k5(exact) - 1952*k6(exact);
D(exact,7) = D(exact,7) + (5946283035*sk - 1786235220*sk2 + 319642092*sk3 - 53155872*sk4 + 2997456*sk5 - 240960*sk6 + 3904*sk7).*dawsonk;
D(exact,7) = D(exact,7) - (6486854220 + 2820371400*k(exact) + 537213600*k2(exact) + 56548800*k3(exact) + 3326400*k4(exact) + 88704*k5(exact)).*dawsonk2;
D(exact,7) = D(exact,7)*(65*sqrt(pi)/65536)./k7(exact).*idawsonk2;

% approximation
D(approx,2) = 4/3 + 16/63*k(approx) - 16/315*k2(approx) - 128/6237*k3(approx);
D(approx,2) = D(approx,2)*sqrt(pi/5);

D(approx,3) = 16/105*k(approx) + 32/1155*k2(approx) - 3712/675675*k3(approx) - 5888/2837835*k4(approx);
D(approx,3) = D(approx,3)*sqrt(pi);

D(approx,4) = 16/231*k2(approx) + 128/10395*k3(approx) - 256/106029*k4(approx);
D(approx,4) = D(approx,4)*sqrt(pi/13);

D(approx,5) = 128/19305*k3(approx) + 256/220077*k4(approx);
D(approx,5) = D(approx,5)*sqrt(pi/17);

D(approx,6) = 64/138567*k4(approx);
D(approx,6) = D(approx,6)*sqrt(pi/21);

D(approx,7) = 256/50702925*k5(approx);
D(approx,7) = D(approx,7)*sqrt(pi);

