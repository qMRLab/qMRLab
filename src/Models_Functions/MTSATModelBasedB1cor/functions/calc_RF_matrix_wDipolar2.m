function RF_mat = calc_RF_matrix_wDipolar2(Params) 
% version 2 shifts to equation from Lee et al 2011;
% Matrix containing parameters affecting only longitudinal mag values

Rrfa = (Params.w1^2 * Params.T2a) / (1 + (2*pi*Params.delta*Params.T2a)^2);

if strcmp(Params.lineshape, 'superLor') % default is gaussian
    Rrfb = pi.*Params.w1.^2.* superlor6(Params.T2b,Params.delta);
    wloc = sqrt(1/(15*Params.T2b^2)); % saturation impacting dipolar pool (Morrison et al 1995)

else
    Rrfb = Params.w1.^2 .* gaussLineShape(Params.T2b,Params.delta);
    wloc = sqrt(1/(3*Params.T2b^2)); % saturation impacting dipolar pool (Morrison et al 1995)
end

%% Form the matrix
if strcmp( Params.freqPattern,'dualContinuous') 
    % continuous dual saturation removes/uncouples the dipolar pool;

    RF_mat = [-(Params.Ra + Params.R*Params.M0b + Rrfa),       Params.R*Params.M0a,             0;...
              Params.R*Params.M0b,                -(Params.Rb + Rrfb + Params.R*Params.M0a),    0;... 
                            0,                               0,                                 -1/Params.T1D]; %include T1D to prevent singular matrix

else
    % single and dualAlternate will use the same equations
    %D = (2*pi * Params.delta / D)^2;

    % % only longitudinal values
    RF_mat = [-(Params.Ra + Params.R*Params.M0b + Rrfa),       Params.R*Params.M0a,                    0;...
               Params.R*Params.M0b,                -(Params.Rb + Rrfb + Params.R*Params.M0a),     2*pi*Params.delta * Rrfb / wloc;... 
                                0,                           Rrfb * (2*pi*Params.delta/wloc),    -(Rrfb*(2*pi*Params.delta/wloc)^2 + 1/Params.T1D)];
end
