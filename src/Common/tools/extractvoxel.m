function S = extractvoxel(S,Voxel,fields)
if ~exist('fields','var'), fields = fieldnames(S); end
if ~exist('Voxel','var') || isempty(Voxel), disp('interactive voxel selection not implemented yet. Please contribute on github.com/neuropoly/qMRLab.'); return; end
if length(Voxel)<3, Voxel(3)=1; end

% Ensure Voxel indices are within bounds
for ff = 1:length(fields)
    if Voxel(1) > size(S.(fields{ff}), 1) || Voxel(2) > size(S.(fields{ff}), 2) || Voxel(3) > size(S.(fields{ff}), 3)
        error('Voxel indices exceed array bounds for field: %s', fields{ff});
    end
    try
        S.(fields{ff}) = squeeze(S.(fields{ff})(Voxel(1),Voxel(2),Voxel(3),:));
    catch
        S.(fields{ff}) = S.(fields{ff})(Voxel(1),Voxel(2),Voxel(3),:);
    end
end