function Mf = SIRFSE_fun( x, xdata, FitOpt )

% ----------------------------------------------------------------------------------------------------
% SIRFSE_fun Analytical solution for SIRFSE MT data used for fitting
% ----------------------------------------------------------------------------------------------------
% x = [F, kr, R1f, R1r, Sf, Sr, M0f]
% xData = [ti, td]
% Output : Mf
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% Reference : Li, K., Zu, Z., Xu, J., Janve, V. A., Gore, J. C., Does, M. D., & Gochberg, D. F. (2010).
% Optimized inversion recovery sequences for quantitative T1 and magnetization transfer imaging.
% Magn Reson Med, 64(2), 491–500.
% ----------------------------------------------------------------------------------------------------

ti = xdata(:,1);
td = xdata(:,2);

F   = x(1);
kr  = x(2);
R1f = x(3);
R1r = x(4);
Sf  = x(5);
Sr  = x(6);
M0f = x(7);
kf  = kr.*F;

if ( FitOpt.R1reqR1f )
     R1r = x(3);
end

if (isfield(FitOpt,'R1') && ~isempty(FitOpt.R1) && FitOpt.R1map)
    tmpParam = struct('F', F, 'kf', kf, 'R1r', R1r); % Create temp struct with required fields
    R1f = computeR1(tmpParam, FitOpt.R1);
    clear tmpParam % Not needed after this point
end

R1_P = 1/2.*(R1f+R1r+kf+kr + sqrt((R1f-R1r+kf-kr)^2 + 4.*kf.*kr)); %R1+ fast rate
R1_M = 1/2.*(R1f+R1r+kf+kr - sqrt((R1f-R1r+kf-kr)^2 + 4.*kf.*kr)); %R1- slow rate

% Recovery from zero after FSE
Mf_td_M = -(R1f - R1_M) / (R1_P - R1_M) .* exp(-R1_P.*td) + ...
           (R1f - R1_P) / (R1_P - R1_M) .* exp(-R1_M.*td) +1;   %Mf(td-)/Mf0
       
Mr_td_M = -(R1r - R1_M) / (R1_P - R1_M) .* exp(-R1_P.*td) + ...
           (R1r - R1_P) / (R1_P - R1_M) .* exp(-R1_M.*td) +1;   %Mr(td-)/Mr0  

% Inversion pulse
Mf_td_P = Sf .* Mf_td_M;	% Mf(td+)/Mf0
Mr_td_P = Sr .* Mr_td_M;	% Mr(td+)/Mr0

% Recovery during ti
bf_P =  ((Mf_td_P - 1) .* (R1f - R1_M) + (Mf_td_P - Mr_td_P).*kf) / (R1_P - R1_M); 	%bf+
bf_M = -((Mf_td_P - 1) .* (R1f - R1_P) + (Mf_td_P - Mr_td_P).*kf) / (R1_P - R1_M);  %bf-

%Measured signal
Mf = abs( M0f.*(bf_P .* exp(-R1_P.*ti) + bf_M .* exp(-R1_M.*ti) +1) );

end

