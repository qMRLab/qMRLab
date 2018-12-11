function Mz = vfa_equation(params)
%VFA_EQUATIONS Analytical equations for the longitudinal magnetization of
%steady-state gradient echo experiments.
%
%   Reference: Stikov, N. , Boudreau, M. , Levesque, I. R.,
%   Tardif, C. L., Barral, J. K. and Pike, G. B. (2015), On the
%   accuracy of T1 mapping: Searching for common ground. Magn.
%   Reson. Med., 73: 514-522. doi:10.1002/mrm.25135
%
%   params: Struct.
%           Properties: T1, TR, EXC_FA, constant (optional)
%

try
    T1 = params.T1;
    TR = params.TR;
    EXC_FA = params.EXC_FA; % In degrees

    try
        constant = params.constant;
    catch
        constant = 1;
    end
    
    Mz = constant .* ( (1 - exp(-TR/T1)) ./  (1 - cosd(EXC_FA) .* exp(-TR/T1))) .* sind(EXC_FA);
catch
    error('vfa_equation: Incorrect parameters for given flag.  Run `help vfa_equation` for more info.')
end

end
