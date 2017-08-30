function [ Prot, check] = checkInBoundsAndUptade(Prot,LSP,planes)
% check if the scheme parameters in 'scheme' are within the bounds defined
% by the polygon defined by planes

outpolyhedron = max(Prot*planes(:,1:(end-1))'<-repmat(planes(:,4)',size(Prot,1),1),[],2);
Prot(~~outpolyhedron,:) = LSP(randi(size(LSP,1),sum(outpolyhedron),1),:);
check = ~outpolyhedron;
end