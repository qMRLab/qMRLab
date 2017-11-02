function [ Prot, check] = checkInBoundsAndUptade(Prot,LSP,planes)
% check if the scheme parameters in 'scheme' are within the bounds defined
% by the polygon defined by planes

outpolyhedron = max(Prot*planes(:,1:(end-1))'<-repmat(planes(:,end)',size(Prot,1),1),[],2);
Prot(~~outpolyhedron,:) = LSP(randi(size(LSP,1),sum(outpolyhedron),1),:);
check = ~outpolyhedron;

% Take the closest value in LSP
% [~,mindist] = min(pdist2(LSP,Prot),[],1);
% Prot = LSP(mindist,:);

end