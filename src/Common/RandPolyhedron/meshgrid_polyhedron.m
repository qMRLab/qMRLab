function LSP = meshgrid_polyhedron(planes)
% LSP = meshgrid_polyhedron(planes)
%
% EXAMPLE:
%
% TEmax = 120;
% Treadout = 35;
% T180 = 10;
% deltamin=3;
% Gmax = 80;
% % |G| Delta delta
% planes = [0 -1 -1 TEmax % TE-delta-DELTA>0
%     0  1 -1 0     % Delta-delta>0
%     0  0  1 -deltamin % delta - deltamin>0
%     1  0  0 0     % G>0
%     -1 0  0 Gmax];   % Gmax - |G| > 0
%
%
% LSP = MESHGRID_POLYHEDRON(planes);
%
%
% scatter3(LSP(:,1),LSP(:,2),LSP(:,3))
   X = plotregion(planes(:,1:end-1),-planes(:,end));
            if ~sum(X), error('your planes (i.e. inequalities) don''t define a closed area'); end
            Xm = min(X(:,2:end),[],2);
            XM = max(X(:,2:end),[],2);
LSP = {};
for iv=1:size(X,1), LSP{iv} = linspace(Xm(iv),XM(iv),50); end   
% create grid
[LSP{:}]=ndgrid(LSP{:}); LSP = cat(length(LSP)+1,LSP{:});
dim=size(LSP);
LSP = reshape(permute(LSP,[length(dim) 1:(length(dim)-1)]),dim(end),[])';
% manage inequalties
outpolyhedron = max(LSP*planes(:,1:(end-1))'<-repmat(planes(:,end)',size(LSP,1),1),[],2);
LSP = LSP(~outpolyhedron,:);


            