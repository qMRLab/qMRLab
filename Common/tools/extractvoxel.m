function S = extractvoxel(S,Voxel,fields)
if ~exist('fields','var'), fields = fieldnames(S); end
for ff = 1:length(fields)
    S.(fields{ff}) = squeeze(S.(fields{ff})(Voxel(1),Voxel(2),Voxel(3),:));
end