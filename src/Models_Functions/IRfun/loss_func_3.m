function lossVal = loss_func_3(x, TR, TI, data)
params.TR = TR;
params.TI = TI;

params.constant = x(1);
params.T1 = x(2);

lossVal = inversion_recovery.analytical_solution(params, 'GRE-IR', 3) - data;
end