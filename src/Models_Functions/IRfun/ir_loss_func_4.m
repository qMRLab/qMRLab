function lossVal = ir_loss_func_4(x, TI, data)
% Objective loss function for fit_lm method of inversion_recovery model

params.TI = TI;

params.constant = x(1);
params.T1 = x(2);

lossVal = inversion_recovery.analytical_solution(params, 'GRE-IR', 4) - data;
end