function S = extractvoxel(S,Voxel,fields)
if ~exist('fields','var'), fields = fieldnames(S); end
if ~exist('Voxel','var') || isempty(Voxel), disp('interactive voxel selection not implemented yet. Please contribute on github.com/neuropoly/qMRLab.'); end
if length(Voxel)<3, Voxel(3)=1; end
for ff = 1:length(fields)
    S.(fields{ff}) = squeeze(S.(fields{ff})(Voxel(1),Voxel(2),Voxel(3),:));
end