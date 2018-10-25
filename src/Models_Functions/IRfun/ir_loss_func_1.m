function lossVal = ir_loss_func_1(x, TR, TI, data)
% Objective loss function for fit_lm method of inversion_recovery model

params.TR = TR;
params.TI = TI;

params.constant = x(1);
params.T1 = x(2);
params.EXC_FA = x(3);
params.INV_FA = x(4);

lossVal = inversion_recovery.analytical_solution(params, 'GRE-IR', 1) - data;
end
