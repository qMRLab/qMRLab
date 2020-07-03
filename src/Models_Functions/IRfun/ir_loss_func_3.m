function lossVal = ir_loss_func_3(x, TR, TI, data, dataType)
% Objective loss function for fit_lm method of inversion_recovery model

params.TR = TR;
params.TI = TI;

if exist('dataType', 'var') && strcmp(dataType,'complex')
    params.constant = x(1);
    params.T1 = x(3);
    
    lossVal(:,1) = inversion_recovery.analytical_solution(params, 'GRE-IR', 3) - real(data);

    params.constant = x(2);
    lossVal(:,2) = inversion_recovery.analytical_solution(params, 'GRE-IR', 3) - imag(data);
else
    params.constant = x(1);
    params.T1 = x(2);

    lossVal = inversion_recovery.analytical_solution(params, 'GRE-IR', 3) - data;
end

end