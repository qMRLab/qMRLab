function Sf = BuildSfTablePar(angles, offsets, T2f, Trf, shape, PulseOpt)
%BuildSfTable Precompute the values of Sf for a range of MT pulse angles,
%offsets and T2f values.

if (nargin < 6); PulseOpt = struct; end
nA = length(angles);
nO = length(offsets);
nT = length(T2f);
values = zeros(nA*nO*nT,1);

Angles = repmat(angles', nO*nT, 1);
Offsets = repmat(offsets, nA, nT);
Offsets = reshape(Offsets, [nA*nO*nT 1]);
t2f = repmat(T2f, nA*nO, 1);
t2f = reshape(t2f, [nA*nO*nT 1]);

parfor_progress(nA*nO*nT);
parfor ii = 1:nA*nO*nT
	MTpulse = GetPulse(Angles(ii),Offsets(ii),Trf,shape,PulseOpt);
	values(ii) = computeSf(t2f(ii), MTpulse);
    parfor_progress;
end
parfor_progress(0);
values = reshape(values, [nA nO nT]);

Sf.angles  =  angles;
Sf.offsets =  offsets;
Sf.T2f     =  T2f;
Sf.values  =  values;
Sf.PulseShape = shape;
Sf.PulseTrf = Trf;
Sf.PulseOpt = PulseOpt;

end