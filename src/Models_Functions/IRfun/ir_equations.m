function signal = ir_equations(params, flag)
%IR_EQUATIONS Summary of this function goes here
%   Detailed explanation goes here
    
switch flag
    case 'IdealInversion'
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
        	error('ir_equations.IdealInversion: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
        end
    case 'IdealInversion_IgnoreExcitationAndT2'
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
        	error('ir_equations.IdealInversion_IgnoreExcitationAndT2: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
        end

     case 'IdealInversion_IgnoreExcitationAndT2_LongTR'
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
        	error('ir_equations.IdealInversion_IgnoreExcitationAndT2: Incorrect parameters for given flag.  Run `help ir_equations` for more info.')
        end
        
    otherwise
        error('ir_equations: Unknown flag. Run `help ir_equations` for more info.')
end

end

