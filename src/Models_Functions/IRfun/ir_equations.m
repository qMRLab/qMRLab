function Mz = ir_equations(params, seqFlag, approxFlag)
%IR_EQUATIONS Analytical equations for the longitudinal magnetization of 
%steady-state inversion recovery experiments with either a gradient echo 
%(GRE-IR) or spin-echo (SE-IR) readouts. 
%   Reference: Barral, J. K., Gudmundson, E. , Stikov, N. , Etezadi?Amoli, 
%   M. , Stoica, P. and Nishimura, D. G. (2010), A robust methodology for 
%   in vivo T1 mapping. Magn. Reson. Med., 64: 1057-1067. 
%   doi:10.1002/mrm.22497
%
%   params: struct with the required parameters for the sequence and
%   approximation. See below for list.
%
%   seqFlag: String. Either 'GRE-IR' or 'SE-IR'
%   approxFlag: Integer between 1 and 4.
%       1: General equation (no approximation).
%       2: Ideal 180 degree pulse approximation of case 1.
%       3: Ideal 90 degree pulse approximation of case 2, and readout term
%          absorbed into constant.
%       4: Long TR (TR >> T1) approximation of case 3.
%
%   **PARAMS PROPERTIES**
%   All times in seconds, all angles in degrees.
%  'GRE-IR'
%       case 1: T1, TR, TI, EXC_FA, INV_FA, constant (optional)
%       case 2: T1, TR, TI, EXC_FA, constant (optional)
%       case 3: T1, TR, TI, constant (optional)
%       case 4: T1, TI, constant (optional)
%
%  'SE-IR'
%       case 1: Same as 'GRE-IR' case + SE_FA, TE
%       case 2: Same as 'GRE-IR' case + TE
%       case 3: Same as 'GRE-IR' case + TE
%       case 4: Same as 'GRE-IR' case
%

switch seqFlag
    case 'GRE-IR'
        switch approxFlag
            case 1 % General
                try
                    T1 = params.T1;
                    TR = params.TR;
                    TI = params.TI;
                    
                    EXC_FA = params.EXC_FA; % Excitation pulse in deg
                    INV_FA = params.INV_FA; % Inversion pulse in deg
                    
                    try
                        constant = params.constant;
                    catch
                        constant = 1;
                    end
                    
                    Mz= constant .* ( (1-cosd(INV_FA).*exp(-TR/T1) - (1-cosd(INV_FA)).*exp(-TI./T1)) ./ (1-cosd(INV_FA).*cosd(EXC_FA).*exp(-TR./T1)) );
                catch
                    error('ir_equations.GRE-IR.case1: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
            case 2 % Ideal 180 pulse
                try
                    T1 = params.T1;
                    TR = params.TR;
                    TI = params.TI;
                    
                    EXC_FA = params.EXC_FA; % in deg
                    
                    try
                        constant = params.constant;
                    catch
                        constant = 1;
                    end
                    
                    Mz= constant .* (1 - 2*exp(-TI./T1) + exp(-TR./T1));
                catch
                    error('ir_equations.GRE-IR.case2: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
            case 3 % Ideal 90 pulse.
                try
                    T1 = params.T1;
                    TR = params.TR;
                    TI = params.TI;
                    
                    try
                        constant = params.constant;
                    catch
                        constant = 1;
                    end
                    
                    Mz= constant .* (1 - 2*exp(-TI./T1) + exp(-TR./T1));
                catch
                    error('ir_equations.GRE-IR.case3: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
                
            case 4 % Long TR (TR >> T1)
                try
                    T1 = params.T1;
                    TI = params.TI;
                    
                    try
                        constant = params.constant;
                    catch
                        constant = 1;
                    end
                    
                    Mz= constant .* (1 - 2*exp(-TI./T1));
                catch
                    error('ir_equations.GRE-IR.case4: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
                
            otherwise
                error('ir_equations: Unknown flag. Run `help ir_equations` for more info.')
        end
    case 'SE-IR'
        switch approxFlag
            case 1 % General equation
                try
                    T1 = params.T1;
                    TR = params.TR;
                    TI = params.TI;
                    
                    TE = params.TE;
                    
                    EXC_FA = params.EXC_FA; % Excitation pulse in deg
                    INV_FA = params.INV_FA; % Inversion pulse in deg
                    SE_FA = params.SE_FA; % Inversion pulse in deg
                    
                    try
                        constant = params.constant;
                    catch
                        constant = 1;
                    end
                    
                    Mz= constant .* ( (1-cosd(INV_FA).*cosd(SE_FA).*exp(-TR/T1) - cosd(INV_FA).*(1-cosd(SE_FA)).*exp(-(TR-(TE/2))./T1) - (1-cosd(INV_FA)).*exp(-TI./T1)) ./ (1-cosd(INV_FA).*cosd(EXC_FA).*cosd(SE_FA).*exp(-TR./T1)) );
                catch
                    error('ir_equations.SE-IR.case1: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
            case 2 % Ideal 180 pulses
                try
                    T1 = params.T1;
                    TR = params.TR;
                    TI = params.TI;
                    
                    TE = params.TE;
                    
                    EXC_FA = params.EXC_FA; % Excitation pulse in deg
                    
                    try
                        constant = params.constant;
                    catch
                        constant = 1;
                    end
                    
                    Mz= constant .* ( (1-exp(-TR/T1) + 2.*exp(-(TR-(TE/2))./T1) - 2.*exp(-TI./T1)) ./ (1-cosd(EXC_FA).*exp(-TR./T1)) );
                catch
                    error('ir_equations.SE-IR.case2: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
            case 3 % Ideal 90 pulse
                try
                    T1 = params.T1;
                    TR = params.TR;
                    TI = params.TI;
                    
                    TE = params.TE;
                    
                    try
                        constant = params.constant;
                    catch
                        constant = 1;
                    end
                    
                    Mz= constant .* (1-exp(-TR/T1) + 2.*exp(-(TR-(TE/2))./T1) - 2.*exp(-TI./T1));
                catch
                    error('ir_equations.SE-IR.case3: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
            case 4 % Long TR
                try
                    T1 = params.T1;
                    TI = params.TI;
                    
                    try
                        constant = params.constant;
                    catch
                        constant = 1;
                    end
                    
                    Mz= constant .* (1 - 2.*exp(-TI./T1));
                catch
                    error('ir_equations.SE-IR.case4: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
        end
    otherwise
        error('ir_equations.seqFlag: Incorrect seqFlag arguement. Must be either GRE-IR or SE-IR.')
end
