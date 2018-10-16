function test_suite=inversion_recovery_Test
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

% inversion_recovery.analytical_solution tests
function test_analytical_solution_gre_case_1_shape
    
    seqFlag = 'GRE-IR';
    approxFlag = 1;

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.T1 = 900;
    params.TR = 5000;
    params.TI = 50:50:1500;

    Mz = inversion_recovery.analytical_solution(params, seqFlag, approxFlag);
    
    assertTrue(Mz(1) < 0);
    assertTrue(Mz(end) > 0);

function test_analytical_solution_gre_case_2_eq_1
    seqFlag = 'GRE-IR';

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.T1 = 900;
    params.TR = 5000;
    params.TI = 50:50:1500;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_2 = inversion_recovery.analytical_solution(params, seqFlag, 2);

    assertTrue(all(abs(Mz_1-Mz_2)<eps));

function test_analytical_solution_gre_case_2_neq_1
    seqFlag = 'GRE-IR';

    params.EXC_FA = 90;
    params.INV_FA = 170;
    params.T1 = 900;
    params.TR = 5000;
    params.TI = 50:50:1500;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_2 = inversion_recovery.analytical_solution(params, seqFlag, 2);

    assertFalse(all(abs(Mz_1-Mz_2)<eps));

function test_analytical_solution_gre_case_3_eq_1
    seqFlag = 'GRE-IR';

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.T1 = 900;
    params.TR = 5000;
    params.TI = 50:50:1500;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_3 = inversion_recovery.analytical_solution(params, seqFlag, 3);

    assertTrue(all(abs(Mz_1-Mz_3)<eps));

function test_analytical_solution_gre_case_3_neq_1
    seqFlag = 'GRE-IR';

    params.EXC_FA = 80;
    params.INV_FA = 180;
    params.T1 = 900;
    params.TR = 5000;
    params.TI = 50:50:1500;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_3 = inversion_recovery.analytical_solution(params, seqFlag, 3);

    assertFalse(all(abs(Mz_1-Mz_3)<eps));

function test_analytical_solution_gre_case_4_eq_1
    seqFlag = 'GRE-IR';

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.T1 = 900;
    params.TR = params.T1*100;
    params.TI = 50:50:1500;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_4 = inversion_recovery.analytical_solution(params, seqFlag, 4);

    assertTrue(all(abs(Mz_1-Mz_4)<eps));

function test_analytical_solution_gre_case_4_neq_1
    seqFlag = 'GRE-IR';

    params.EXC_FA = 80;
    params.INV_FA = 180;
    params.T1 = 900;
    params.TR = params.T1*1;
    params.TI = 50:50:1500;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_4 = inversion_recovery.analytical_solution(params, seqFlag, 4);

    assertFalse(all(abs(Mz_1-Mz_4)<eps));

function test_analytical_solution_se_case_1_shape
    
    seqFlag = 'SE-IR';
    approxFlag = 1;

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.SE_FA = 180;
    params.T1 = 900;
    params.TR = 5000;
    params.TI = 50:50:1500;
    params.TE = 5;

    Mz = inversion_recovery.analytical_solution(params, seqFlag, approxFlag);
    
    assertTrue(Mz(1) < 0);
    assertTrue(Mz(end) > 0);

function test_analytical_solution_se_case_2_eq_1
    seqFlag = 'SE-IR';

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.SE_FA = 180;
    params.T1 = 900;
    params.TR = 5000;
    params.TI = 50:50:1500;
    params.TE = 5;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_2 = inversion_recovery.analytical_solution(params, seqFlag, 2);

    assertTrue(all(abs(Mz_1-Mz_2)<eps));

function test_analytical_solution_se_case_2_neq_1
    seqFlag = 'SE-IR';

    params.EXC_FA = 90;
    params.INV_FA = 170;
    params.SE_FA = 170;
    params.T1 = 900;
    params.TR = 5000;
    params.TI = 50:50:1500;
    params.TE = 5;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_2 = inversion_recovery.analytical_solution(params, seqFlag, 2);

    assertFalse(all(abs(Mz_1-Mz_2)<eps));

function test_analytical_solution_se_case_3_eq_1
    seqFlag = 'SE-IR';

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.SE_FA = 180;
    params.T1 = 900;
    params.TR = 5000;
    params.TI = 50:50:1500;
    params.TE = 5;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_3 = inversion_recovery.analytical_solution(params, seqFlag, 3);

    assertTrue(all(abs(Mz_1-Mz_3)<eps));

function test_analytical_solution_se_case_3_neq_1
    seqFlag = 'SE-IR';

    params.EXC_FA = 80;
    params.INV_FA = 180;
    params.SE_FA = 180;
    params.T1 = 900;
    params.TR = 5000;
    params.TI = 50:50:1500;
    params.TE = 5;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_3 = inversion_recovery.analytical_solution(params, seqFlag, 3);

    assertFalse(all(abs(Mz_1-Mz_3)<eps));

function test_analytical_solution_se_case_4_eq_1
    seqFlag = 'SE-IR';

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.SE_FA = 180;
    params.T1 = 900;
    params.TR = params.T1*100;
    params.TI = 50:50:1500;
    params.TE = 5;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_4 = inversion_recovery.analytical_solution(params, seqFlag, 4);

    assertTrue(all(abs(Mz_1-Mz_4)<eps));

function test_analytical_solution_se_case_4_neq_1
    seqFlag = 'SE-IR';

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.SE_FA = 180;
    params.T1 = 900;
    params.TR = params.T1*1;
    params.TI = 50:50:1500;
    params.TE = 5;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);
    Mz_4 = inversion_recovery.analytical_solution(params, seqFlag, 4);

    assertFalse(all(abs(Mz_1-Mz_4)<eps));

% inversion_recovery.bloch_sim tests
function test_bloch_sim_eq_analytical_at_steady_state

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.T1 = 900;
    params.T2 = 40;
    params.TR = 5000;
    params.TI = 50:50:1500;
    params.TE = 5;
    params.Nex = 100;
    
    Mz_analytical = inversion_recovery.analytical_solution(params, 'GRE-IR', 1);
    Mz_blochSim = inversion_recovery.bloch_sim(params);

    assertTrue(all(abs(Mz_analytical-Mz_blochSim)< (eps*10))); % Give slightly more difference leeway due to more calculations in bloch_sim

% inversion_recovery.fit_lm tests

function test_fit_lm_1_returns_T1_within_5pc
    seqFlag = 'GRE-IR';

    params.EXC_FA = 100;
    params.INV_FA = 170;
    params.T1 = 900;
    params.TR = params.T1*3;
    params.TI = 50:50:1500;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);

    fitVals = inversion_recovery.fit_lm(Mz_1, params, 1);
    fittedT1 = fitVals.T1;
    
    assertTrue(all(abs(fittedT1-params.T1 ) < (params.T1 * (5/100)) ));

function test_fit_lm_2_returns_T1_within_5pc
    seqFlag = 'GRE-IR';

    params.EXC_FA = 75;
    params.INV_FA = 180;
    params.T1 = 900;
    params.TR = params.T1*3;
    params.TI = 50:50:1500;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);

    fitVals = inversion_recovery.fit_lm(Mz_1, params, 2);
    fittedT1 = fitVals.T1;
    
    assertTrue(all(abs(fittedT1-params.T1 ) < (params.T1 * (5/100)) ));

function test_fit_lm_3_returns_T1_within_5pc
    seqFlag = 'GRE-IR';

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.T1 = 900;
    params.TR = params.T1*3;
    params.TI = 50:50:1500;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);

    fitVals = inversion_recovery.fit_lm(Mz_1, params, 3);
    fittedT1 = fitVals.T1;
    
    assertTrue(all(abs(fittedT1-params.T1 ) < (params.T1 * (5/100)) ));

function test_fit_lm_4_returns_T1_within_5pc_for_long_TR_case
    seqFlag = 'GRE-IR';

    params.EXC_FA = 90;
    params.INV_FA = 180;
    params.T1 = 900;
    params.TR = params.T1*5;
    params.TI = 50:50:1500;

    Mz_1 = inversion_recovery.analytical_solution(params, seqFlag, 1);

    fitVals = inversion_recovery.fit_lm(Mz_1, params, 4);
    fittedT1 = fitVals.T1;
    
    assertTrue(all(abs(fittedT1-params.T1 ) < (params.T1 * (5/100)) ));
