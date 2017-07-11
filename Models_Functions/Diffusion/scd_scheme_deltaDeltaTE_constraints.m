function [ x,y ] = scd_scheme_deltaDeltaTE_constraints( TE, Treadout, T_RF180, deltaMin )
% tri_Dd( TE, Treadout, T_RF180, deltaMin )
% display 2D space of feasible DELTA delta for the set of parameters in input
%
% Constraints : 
% DELTA + delta + Tro/2 <= TE
% DELTA >= delta + T_RF180 

DELTAMin = deltaMin + T_RF180;

x1 = deltaMin;
y1 = DELTAMin;

x2 = 0.5*(TE - Treadout - T_RF180);
y2 = -x2 + TE - Treadout;

x3 = deltaMin;
y3 = -deltaMin + TE - Treadout;

x = [x1 x2 x3];
y = [y1 y2 y3]; 



% fill(x, y, 'r')
% xlabel('\delta (in ms)')
% ylabel('\Delta (in ms)')
% title({'2D space of feasible (\Delta,\delta) combinations' ; ['TE : ', num2str(TE),' ms', '   ','Treadout : ', num2str(Treadout),' ms', '   ']});

end

