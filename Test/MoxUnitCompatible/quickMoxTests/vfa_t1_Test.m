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
