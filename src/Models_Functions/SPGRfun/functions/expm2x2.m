function E = expm2x2(M)
%EXPM2X2 Closed-form matrix exponential of a real 2x2 matrix.
%
%   E = EXPM2X2(M) returns expm(M) for real 2x2 M, using Putzer's method:
%
%       expm(M) = e^s * ( c0*I + c1*(M - s*I) ),   s = trace(M)/2
%
%   where, with disc = s^2 - det(M) and q = sqrt(|disc|),
%
%       disc > 0   ->   c0 = cosh(q),  c1 = sinh(q)/q     (real eigenvalues)
%       disc < 0   ->   c0 = cos(q),   c1 = sin(q)/q      (complex pair)
%       disc == 0  ->   c0 = 1,        c1 = 1             (repeated eigenvalue)
%
%   This is exact rather than approximate: MATLAB's general expm uses scaling
%   and squaring with a Pade approximant, which is built for arbitrary sizes and
%   is heavily oversized for 2x2. In the SPGR two-pool propagator the matrices
%   are
%
%       A = [R1f+kf, -kr; -kf, R1r+kr(+W)]
%
%   so det = a*d - kr*kf and disc = ((a-d)/2)^2 + kr*kf. Both exchange rates are
%   strictly positive, so disc > 0 always and the real-eigenvalue branch is the
%   only one taken in practice; the others are guards, not live paths.
%
%   Note this returns values that differ from expm() in the last few digits --
%   it replaces an approximation with a closed form, so where they differ this
%   one is the more accurate of the two.

a = M(1,1); b = M(1,2); c = M(2,1); d = M(2,2);

s    = 0.5*(a + d);
disc = s*s - (a*d - b*c);

if disc > 1e-14
    q  = sqrt(disc);
    c0 = cosh(q);
    c1 = sinh(q)/q;
elseif disc < -1e-14
    q  = sqrt(-disc);
    c0 = cos(q);
    c1 = sin(q)/q;
else
    c0 = 1;
    c1 = 1;
end

es = exp(s);
E  = [ es*(c0 + c1*(a - s)),  es*(c1*b) ; ...
       es*(c1*c),             es*(c0 + c1*(d - s)) ];

end
