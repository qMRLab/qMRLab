function signal = ir_equations(params, seqFlag, approxFlag)
%IR_EQUATIONS Summary of this function goes here
%   Detailed explanation goes here

switch seqFlag
    case 'GRE-IR'
        switch approxFlag
            case 1 % General
                try
                    T1 = params.T1;
                    TR = params.TR;
                    TI = params.TI;
                    
                    TE = params.TE;
                    T2 = params.T2;
                    
                    FA = params.FA; % Excitation pulse in deg
                    INV_FA = params.INV_FA; % Inversion pulse in deg
                    
                    try
                        signalConstant = params.signalConstant;
                    catch
                        signalConstant = 1;
                    end
                    
                    signal = signalConstant .* (exp(-TE./T2) .* sind(FA)) .* ( (1-cosd(INV_FA).*exp(-TR/T1) - (1-cosd(INV_FA)).*exp(-TI./T1)) ./ (1-cosd(INV_FA).*cosd(FA).*exp(-TR./T1)) );
                catch
                    error('ir_equations.GRE-IR.case1: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
            case 2 % Ideal 180 pulse
                try
                    T1 = params.T1;
                    TR = params.TR;
                    TI = params.TI;
                    
                    TE = params.TE;
                    T2 = params.T2;
                    
                    FA = params.FA; % in deg
                    
                    try
                        signalConstant = params.signalConstant;
                    catch
                        signalConstant = 1;
                    end
                    
                    signal = signalConstant .* (1 - 2*exp(-TI./T1) + exp(-TR./T1)) .* exp(-TE./T2) .* sind(FA);
                catch
                    error('ir_equations.GRE-IR.case2: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
            case 3 % Ideal FA, and T2 term absorbed in signal constant
                try
                    T1 = params.T1;
                    TR = params.TR;
                    TI = params.TI;
                    
                    try
                        signalConstant = params.signalConstant;
                    catch
                        signalConstant = 1;
                    end
                    
                    signal = signalConstant .* (1 - 2*exp(-TI./T1) + exp(-TR./T1));
                catch
                    error('ir_equations.GRE-IR.case3: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
                
            case 4 % Long TR
                try
                    T1 = params.T1;
                    TI = params.TI;
                    
                    try
                        signalConstant = params.signalConstant;
                    catch
                        signalConstant = 1;
                    end
                    
                    signal = signalConstant .* (1 - 2*exp(-TI./T1));
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
                    T2 = params.T2;

                    FA = params.FA; % Excitation pulse in deg
                    INV_FA = params.INV_FA; % Inversion pulse in deg
                    SE_FA = params.SE_FA; % Inversion pulse in deg

                    try
                        signalConstant = params.signalConstant;
                    catch
                        signalConstant = 1;
                    end

                    signal = signalConstant .* (exp(-TE./T2) .* sind(FA)) .* ( (1-cosd(INV_FA).*cosd(SE_FA).*exp(-TR/T1) - cosd(INV_FA).*(1-cosd(SE_FA)).*exp(-(TR-(TE/2))./T1) - (1-cosd(INV_FA)).*exp(-TI./T1)) ./ (1-cosd(INV_FA).*cosd(FA).*cosd(SE_FA).*exp(-TR./T1)) );
                catch
                    error('ir_equations.SE-IR.case1: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
            case 2 % Ideal 180 pulses
                try
                    T1 = params.T1;
                    TR = params.TR;
                    TI = params.TI;

                    TE = params.TE;
                    T2 = params.T2;

                    FA = params.FA; % Excitation pulse in deg

                    try
                        signalConstant = params.signalConstant;
                    catch
                        signalConstant = 1;
                    end

                    signal = signalConstant .* (exp(-TE./T2) .* sind(FA)) .* ( (1-exp(-TR/T1) + 2.*exp(-(TR-(TE/2))./T1) - 2.*exp(-TI./T1)) ./ (1-cosd(FA).*exp(-TR./T1)) );
                catch
                    error('ir_equations.SE-IR.case2: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
            case 3 % Ideal 90,  T2 term absorbed in signal constant
                try
                    T1 = params.T1;
                    TR = params.TR;
                    TI = params.TI;

                    TE = params.TE;

                    try
                        signalConstant = params.signalConstant;
                    catch
                        signalConstant = 1;
                    end

                    signal = signalConstant .* (1-exp(-TR/T1) + 2.*exp(-(TR-(TE/2))./T1) - 2.*exp(-TI./T1));
                catch
                    error('ir_equations.SE-IR.case3: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
            case 4 % Long TR
                try
                    T1 = params.T1;
                    TI = params.TI;

                    try
                        signalConstant = params.signalConstant;
                    catch
                        signalConstant = 1;
                    end

                    signal = signalConstant .* (1 - 2.*exp(-TI./T1));
                catch
                    error('ir_equations.SE-IR.case4: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
                end
        end
    end
end

