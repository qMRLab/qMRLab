function scd_scheme_display_3D_Delta_delta_G( scheme, ~, titleName )

global xd;
global yD;

if isempty(xd)
    C=35;
    [xd,yD] = scd_scheme_deltaDeltaTE_constraints( 100, C, 10, 3);
end
% % Bounds for delta & DELTA ( Jonathan & Al. Acquisition Protocol Optimization for Axon Diameter Mapping at High-Performance Gradient Systems : A Simulation Study)
% xd = [3 17 4];
% yD = [12 23 40];

fill3(xd, yD, 0.*[1 1 1], [1 1 1]); 
hold on
scatter3(scheme(:,6), scheme(:,5), sqrt(sum(scheme(:,[1 2 3]).^2,2)).*scheme(:,4)*1e6, 20, scheme(:,4), 'o');
hold off
% legend('2D space of feasible (\Delta,\delta)','Protocol in (\Delta,\delta,G) space');

xlabel('\delta (in ms)');
ylabel('\Delta (in ms)');
zlabel('|G| (in mT/m)');
grid on

if exist('titleName','var')
title(titleName,'FontWeight','bold');
end

end

