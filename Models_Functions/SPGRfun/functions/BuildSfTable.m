function Sf = BuildSfTable(angles, offsets, T2f, Trf, shape, PulseOpt,oldSf, compute)
%BuildSfTable Precompute the values of Sf for a range of MT pulse angles,
%offsets and T2f values.

nA = length(angles);
nO = length(offsets);
nT = length(T2f);
Sf.values = zeros(nA,nO,nT);

if (nargin < 6); PulseOpt = struct; end

% Check if same as old Sf Table
Sf.angles  =  angles;
Sf.offsets =  offsets;
Sf.T2f     =  T2f;
Sf.PulseShape = shape;
Sf.PulseTrf = Trf;
Sf.PulseOpt = PulseOpt;

if exist('oldSf','var')
    [~,d1,d2] = comp_struct(rmfield(Sf,'values'),rmfield(oldSf,'values'));
    % same as oldSf? return old Sf.
    if isempty(d1) && isempty(d2), Sf = oldSf; return; end
end
if exist('compute','var') && compute==0, Sf=[]; return; end

% Create waitbar
h = waitbar(0,'','Name','Computing Sf table','CreateCancelBtn',...
    'if ~strcmp(get(gcbf,''Name''),''canceling...''), setappdata(gcbf,''canceling'',1); set(gcbf,''Name'',''canceling...''); else delete(gcbf); end');
setappdata(h,'canceling',0)
stop = 0;
ww = 1;

for ii = 1:nA
    for jj = 1:nO
        for kk = 1:nT
            % Allows user to cancel
            if getappdata(h,'canceling'); stop = 1; break; end
            waitbar(ww/(nA*nO*nT),h,sprintf('Data %d/%d', ww, nA*nO*nT));
            
            MTpulse = GetPulse(angles(ii),offsets(jj),Trf,shape,PulseOpt);
            Sf.values(ii,jj,kk) = computeSf(T2f(kk), MTpulse);
            ww = ww+1;
        end
        if (stop); break; end;
    end
    if (stop); break; end;
end

delete(h);
if stop
    Sf=[];
end

end