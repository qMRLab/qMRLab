function Sfi = GetSf(angles, offsets, T2f, SfTable)
%GetSf interpolate Sf values from precomputed table

Sfi = interp3(SfTable.offsets, SfTable.angles, SfTable.T2f, SfTable.values, offsets, angles, T2f*ones(length(angles),1));

nanindex = find(isnan(Sfi));
if ~isempty(nanindex)
    for ii = nanindex
        warning('Cannot interpolate value from current Sf table : angle: %f; offset: %f; T2f: %f\n', angles(ii), offsets(ii), T2f);
        disp('Computing missing Sf value...');
        MTpulse = GetPulse(angles(ii),offsets(ii),SfTable.PulseTrf,SfTable.PulseShape,SfTable.PulseOpt);
        Sfi(ii) = computeSf(T2f, MTpulse);
    end
end