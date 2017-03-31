function FitResultsSave_nii(FitResults)
mkdir FitResults
for i = 1:length(FitResults.fields)
    map = FitResults.fields{i};
    file = strcat(map,'.nii');
    save_nii_v2(make_nii(FitResults.(map)),fullfile('FitResults',file),[],64);
end