function scheme = discrete_delta_Delta(scheme,Ncombi)
% USE KMEANS TO FIND Ncombi OF DELTA / delta
[ind,C]=kmeans(scheme(:,[5 6]),Ncombi);
if max(C(:))<1, C = round(C*1e3)/1e3; else, C = round(C); end
for ii=1:length(ind)
    scheme(ii,[5 6]) = C(ind(ii),:);
end

scheme(:,7) = scheme(:,5)+scheme(:,6);
gyro=42.58; %rad.KHz/mT
scheme(:,8)=gyro.*scheme(:,6).*scheme(:,4); %um-1

% sort by acquisition
acq = unique(scheme(:,5:6), 'rows');
[~, index1] = sort(acq(:,1));
acq = acq(index1,:);
Nacq = size(acq, 1);
for s=1:size(scheme,1)
    [ind,~] = find(sum(abs(acq - repmat(scheme(s,5:6),Nacq,1)), 2) == 0);
    scheme(s,9) = ind;
end
[~, index2]  = sort(scheme(:,9));
scheme = scheme(index2,:);