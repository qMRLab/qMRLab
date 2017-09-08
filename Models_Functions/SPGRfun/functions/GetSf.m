function Sfi = GetSf(angles, offsets, T2f, SfTable)
%GetSf interpolate Sf values from precomputed table

Sfi = zeros(length(angles),1);

for ii = 1:length(angles)
   
[xi, yi, zi] = meshgrid(offsets(ii), angles(ii), T2f);
Sfi(ii) = interp3(SfTable.offsets, SfTable.angles, SfTable.T2f, SfTable.values, xi, yi, zi);

    if (isnan(Sfi(ii)))
        warning('Cannot interpolate value from current Sf table : angle: %f; offset: %f; T2f: %f\n', angles(ii), offsets(ii), T2f); 
        disp('Computing missing Sf value...');
        MTpulse = GetPulse(angles(ii),offsets(ii),SfTable.PulseTrf,SfTable.PulseShape,SfTable.PulseOpt);
        Sfi(ii) = computeSf(T2f, MTpulse);
    end
end