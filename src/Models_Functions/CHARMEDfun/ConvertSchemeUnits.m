function scheme = ConvertSchemeUnits(scheme,sessionnum,in3d)
% convert units
% scheme = ConvertSchemeUnits(scheme,sessionnum,in3d)
% scheme:       [nx7] (Gx Gy Gz Gnorm Delta delta TE) in International System units
% sessionnum:   [logical] 1--> adds a column #9 with session number (unique Delta/delta/TE/(Gnorm))
% in3d:         [logical] 1--> sessionnum will search for different shells (different Gnorm)

scheme(:,4)   = scheme(:,4).*sqrt(sum(scheme(:,1:3).^2,2))*1e-3; % G mT/um
scheme(:,1:3) = scheme(:,1:3)./repmat(sqrt(scheme(:,1).^2+scheme(:,2).^2+scheme(:,3).^2),1,3); scheme(isnan(scheme))=0;
scheme(:,5)   = scheme(:,5)*10^3; % DELTA ms
scheme(:,6)   = scheme(:,6)*10^3; % delta ms
if size(scheme,2)>6
    scheme(:,7) = scheme(:,7)*10^3; % TE ms
else
    scheme(:,7) = scheme(:,5)+scheme(:,6)+35; % approximation
end
gyro = 42.57; % kHz/mT
scheme(:,8) = gyro*scheme(:,4).*scheme(:,6); % um-1

if sessionnum
    if ~exist('in3d','var') || in3d==0
        % differentiate session based on Delta/delta/TE values
        list = unique(scheme(:,7:-1:5),'rows');
        nnn  = size(list,1);
        for j = 1 : nnn
            for i = 1 : size(scheme,1)
                if  scheme(i,7:-1:5) == list(j,:)
                    scheme(i,9) = j;
                end
            end
        end
    else
        % Find different shells
        list_G = unique(round(scheme(:,[4 5 6 7])*1e5)/1e5,'rows');
        nnn = size(list_G,1);
        for j = 1 : nnn
            for i = 1 : size(scheme,1)
                if  min(round(scheme(i,[4 5 6 7])*1e5)/1e5 == list_G(j,:))
                    scheme(i,9) = j;
                end
            end
        end
        scheme(ismember(scheme(:,9),find(list_G(:,1)==0)),9) = find(list_G(:,1)==0,1,'first');
    end
end
end
