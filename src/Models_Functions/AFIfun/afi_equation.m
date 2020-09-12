function [Mz1, Mz2] = afi_equation(params)
%AFI_EQUATIONS Analytical equations for the longitudinal magnetizations of
%steady-state gradient echo experiments for Signal 1 and Signal 2.
%
%   Reference: 
%
%   params: Struct.
%           Properties: T1, TR1, TR2, EXC_FA, constant (optional)
%

try
    T1 = params.T1;
    TR1 = params.TR1;
    TR2 = params.TR2;
    EXC_FA = params.EXC_FA; % In degrees

    try
        constant = params.constant; %M0
    catch
        constant = 1;
    end
    
    Mz1 = constant .* ( (1 - exp(-TR2/T1) + (1 - exp(-TR1/T1)) * exp(-TR2/T1) .* cosd(EXC_FA)) ./  (1 -  exp(-TR1/T1) * exp(-TR2/T1) .* cosd(EXC_FA) .* cosd(EXC_FA)) ) .* sind(EXC_FA);
    Mz2 = constant .* ( (1 - exp(-TR1/T1) + (1 - exp(-TR2/T1)) * exp(-TR1/T1) .* cosd(EXC_FA)) ./  (1 -  exp(-TR1/T1) * exp(-TR2/T1) .* cosd(EXC_FA) .* cosd(EXC_FA)) ) .* sind(EXC_FA);
    
catch
    error('afi_equation: Incorrect parameters for given flag.  Run `help afi_equation` for more info.')
end

end
