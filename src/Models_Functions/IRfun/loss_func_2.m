function lossVal = loss_func_2(x, TR, TI, data)
params.TR = TR;
params.TI = TI;

params.constant = x(1);
params.T1 = x(2);
params.EXC_FA = x(3);

lossVal = inversion_recovery.analytical_solution(params, 'GRE-IR', 2) - data;
end