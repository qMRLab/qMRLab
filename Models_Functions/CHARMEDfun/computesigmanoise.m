function SigmaNoise = computesigmanoise(Prot,data)
Prot(Prot(:,4)==0,1:6) = 0;
% find images that where repeated
[~,c,ind] = consolidator(Prot(:,1:7),[],'count');
cmax = max(c); % find images repeated more than 5 times (for relevant STD)
if cmax<5, uiwait(errordlg('Your dataset doesn''t have 5 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise. Specify a fixed Sigma Noise in the option panel instead. (see scd_noise_fit_histo_nii.m to estimate the noise STD).')); end

repeated_measured = find(ismember(c,c(c>5)));
if ~isempty(repeated_measured)
    for irep = 1:length(repeated_measured)
        vars(irep) = var(data(ind==repeated_measured(irep)));
    end
    SigmaNoise = sqrt(median(vars));
else
    SigmaNoise=0;
end
end
