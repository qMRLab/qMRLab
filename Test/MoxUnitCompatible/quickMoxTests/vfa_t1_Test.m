function test_suite=vfa_t1_Test
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

% vfa_t1.analytical_solution tests
function test_analytical_solution_shape

    params.EXC_FA = 1:90;
    params.T1 = 900;
    params.TR = 15;

    Mz = vfa_t1.analytical_solution(params);
    
    dMz = diff(Mz);
    ernstAngle = vfa_t1.ernst_angle(params);
    eaIndex = find(params.EXC_FA == round(ernstAngle));
    
    % Positive slow at the lowest flip angles
    assertTrue(dMz(1)   > 0);
    
    % Negative slow at the highest flip angles
    assertTrue(dMz(end) < 0);
    
    % Verify that the sign of the derivative changes around the Ernst angle
    % or the sign is exactly 0 at the ernst angle.
    % (sign gives either 1, -1, or 0).
    assertTrue(sign(dMz(eaIndex))                          == 0 || ...
               sign(dMz(eaIndex)) + sign(dMz(eaIndex - 1)) == 0 || ...
               sign(dMz(eaIndex)) + sign(dMz(eaIndex + 1)) == 0);

% vfa_t1.bloch_sim tests
function test_bloch_sim_eq_analytical_at_steady_state

    params.EXC_FA = 1:90;
    params.T1 = 900; % ms
    params.T2 = 1000000000; % Long T2 to minimize decay in signal output
    params.TR = 25; % ms
    params.TE = 5; % ms
    params.Nex = 1000; % High number of Nex to force steady state
    
    Mz_analytical = vfa_t1.analytical_solution(params);
    [Mz_blochsim, Msig_blochSim] = vfa_t1.bloch_sim(params);
    Msig_blochSim = abs(Msig_blochSim); % Complex to magnitude
    
    assertTrue(all(abs(Mz_analytical-Msig_blochSim) < (10^-9))); % Give slightly more difference leeway due to more calculations in bloch_sim

% vfa_t1.find_two_optimal_flip_angles tests
function test_find_two_optimal_flip_angles_below_and_above_ernst_angle

    params.T1 = 900; % ms
    params.TR = 25; % ms
    
    ernstAngle = vfa_t1.ernst_angle(params);
    
    params.EXC_FA = vfa_t1.find_two_optimal_flip_angles(params);
   
    assertTrue(params.EXC_FA(1) < ernstAngle);
    assertTrue(params.EXC_FA(2) > ernstAngle); 

function generate_vfa_t1_notebook 


    eval('Model = vfa_t1');
    qMRgenJNB(Model,pwd);
