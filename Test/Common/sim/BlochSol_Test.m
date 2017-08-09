classdef (TestTags = {'Unit', 'SPGR', 'qMT'}) BlochSol_Test < matlab.unittest.TestCase
%% BLOCHSOL_TEST Test class for BlochSol.m
%
%   --tests--
%   test_no_pulse_mag_remains_unchanged
%       - Assert that a magnetization vector with only longitudinal values
%         remains constant for a constant pulse of 0 degree FA.
%
%   test_no_longi_mag_evol_for_transverse_inital_mag_inf_t2_t1
%       - Assert that a magnetization vector with only transverse values
%         does not accrue longitudinal magnetization for the case of
%         infinite T1 and T2 (0 deg FA).
%
%   test_magn_evols_to_equilibrium_vals
%       - Assert that an empty magnetization vector evolves to the
%         equilibrium longitudinal values (M0f and M0r) after a time
%         much greater than T1f (10x) and 0 deg FA.
%
%   test_mag_goes_to_zero_for_time_much_greater_than_t2f
%       - Assert that a magnetization vector with only transverse values
%         decays to 0 after a time much greater than T2f (x10)
%
%   test_steady_state_smaller_for_small_delta_than_big
%       - Assert that steady-state longitudinal (free) magnization is
%         smaller for the case of a small offset frequency than large 
%         offset freq.
%
%   test_steady_state_larger_for_small_FA_than_big
%       - Assert that steady-state longitudinal (free) magnization is
%         larger for the case of a small flip angle (per millisec) than 
%         large flip angle.
%

    properties
        Param = struct('M0f', 1,           ...
                       'M0r', 0.15,        ...
                       'R1f', 1.1,         ...
                       'R1r', 1,           ...
                       'R2f', 1/0.03,      ...
                       'R2r', 1/(12*10^-6),...
                       'kf',  4.0,         ...
                       'kr',  4.0/0.15);
    end
    
    methods (TestClassSetup)
    end
     
    methods (TestClassTeardown)
    end
    
    methods (Test)
        function test_no_pulse_mag_remains_unchanged(testCase)
            %% Prep
            %
            delta = 200; % On-resonance
            testCase.Param.G = computeG(delta,1/testCase.Param.R2f, 'SuperLorentzian');

            pulseDur = 10; % seconds
            pulseShape = 'hard';
            
            flipAngle = 0; % No pulse
            Pulse = GetPulse(flipAngle, delta, pulseDur, pulseShape);
            
            
            M0 = [0 0 1 0.15]'; % Initial magnetization, Xf Yf Zf Zr
            
            timeRange = linspace(0,10,1000); % in seconds
            
            for ii =1:length(timeRange)
               M(ii, :) = BlochSol(timeRange(ii), M0, testCase.Param, Pulse);
            end
            
            %                    Actual ,  Expected
            testCase.assertEqual(M(end,:), M0', 'AbsTol', 0.001);
        end
        
        function test_no_longi_mag_evol_for_transverse_inital_mag_inf_t2_t1(testCase)
            %% Prep
            %
            Param = testCase.Param;
            
            delta = 100; % Go to the rotating ref frame for this case
            Param.G = computeG(delta,1/Param.R2f, 'SuperLorentzian');

            pulseDur = 0.001; % seconds, near-instantaneous
            pulseShape = 'hard';
            
            
            flipAngle = 0; 
            Pulse = GetPulse(flipAngle, delta, pulseDur, pulseShape);
            
            %***
            Param.R2f = 0.0001; % Assume very large T2f
            Param.R2r = 0.0001; % Assume very large T2r
            Param.R1f = 0.0001; % Assume very large T1f
            Param.R1r = 0.0001; % Assume very large T1r
            %***
            
            M0 = [1 0 0 0]'; % Initial magnetization, Xf Yf Zf Zr
            
            timeRange = linspace(0, 1, 1000); % in seconds
            
            for ii =1:length(timeRange)
               M(ii, :) = BlochSol(timeRange(ii), M0, Param, Pulse);
            end
            
            %                    Actual                     , Expected
            testCase.assertEqual([M(end,3) M(end,4)], [M0(3) M0(4)], 'AbsTol', 0.001);
        end
        
        function test_magn_evols_to_equilibrium_vals(testCase)
            %% Prep
            %
            Param = testCase.Param;
            
            delta = 100; % Go to the rotating ref frame for this case
            Param.G = computeG(delta,1/Param.R2f, 'SuperLorentzian');

            pulseDur = 0.001; % seconds, near-instantaneous
            pulseShape = 'hard';
            
            
            flipAngle = 0; 
            Pulse = GetPulse(flipAngle, delta, pulseDur, pulseShape);
            
            M0 = [0 0 0 0]'; % Initial magnetization, Xf Yf Zf Zr
            
            timeRange = linspace(0, (1/Param.R1f*10), 1000); % in seconds, 10x T1f
            
            for ii =1:length(timeRange)
               M(ii, :) = BlochSol(timeRange(ii), M0, Param, Pulse);
            end
            
            %                    Actual ,  Expected
            testCase.assertEqual(M(end,:), [0 0 Param.M0f Param.M0r], 'AbsTol', 0.001);
        end
        
        function test_mag_goes_to_zero_for_time_much_greater_than_t2f(testCase)
            %% Prep
            %
            Param = testCase.Param;
            
            delta = 100; % Go to the rotating ref frame for this case
            Param.G = computeG(delta,1/Param.R2f, 'SuperLorentzian');

            pulseDur = 0.001; % seconds, near-instantaneous
            pulseShape = 'hard';
            
            
            flipAngle = 0; 
            Pulse = GetPulse(flipAngle, delta, pulseDur, pulseShape);
            
            M0 = [1 0 0 0]'; % Initial magnetization, Xf Yf Zf Zr
            
            timeRange = linspace(0, (1/Param.R2f)*10, 1000); % in seconds, 10x T2f
            
            for ii =1:length(timeRange)
               M(ii, :) = BlochSol(timeRange(ii), M0, Param, Pulse);
            end
            
            %                    Actual ,  Expected
            testCase.assertEqual(M(end,1:2), [0 0], 'AbsTol', 0.001);
        end
        
        function test_steady_state_smaller_for_small_delta_than_big(testCase)
            %% Prep
            %
            Param1 = testCase.Param;
            Param2 = testCase.Param;
            
            delta1 = 100;
            delta2 = 10*delta1;

            Param1.G = computeG(delta1,1/Param1.R2f, 'SuperLorentzian');
            Param2.G = computeG(delta2,1/Param2.R2f, 'SuperLorentzian');

            pulseDur = 10; % seconds
            pulseShape = 'hard';
            
            flipAngle = 40; % FA per millisec 
            Pulse1 = GetPulse((flipAngle*1000)*pulseDur, delta1, pulseDur, pulseShape);
            Pulse2 = GetPulse((flipAngle*1000)*pulseDur, delta2, pulseDur, pulseShape);

            M0 = [0 0 testCase.Param.M0f testCase.Param.M0r]'; % Initial magnetization, Xf Yf Zf Zr
            
            timeRange = linspace(0, pulseDur, 1000); % in seconds, 10x T2f
            
            for ii =1:length(timeRange)
               M1(ii, :) = BlochSol(timeRange(ii), M0, Param1, Pulse1);
               M2(ii, :) = BlochSol(timeRange(ii), M0, Param2, Pulse2);
            end
            
            %                          Small delta, Big delta
            testCase.assertLessThan(M1(end,3)  , M2(end,3));
        end
 
        function test_steady_state_larger_for_small_FA_than_big(testCase)
            %% Prep
            %
            Param = testCase.Param;
            
            delta = 1000;

            Param.G = computeG(delta,1/Param.R2f, 'SuperLorentzian');

            pulseDur = 10; % seconds
            pulseShape = 'hard';
            
            flipAngle1 = 40; % FA per millisec
            flipAngle2 = 2*flipAngle1 ; % FA per millisec 

            Pulse1 = GetPulse((flipAngle1*1000)*pulseDur, delta, pulseDur, pulseShape);
            Pulse2 = GetPulse((flipAngle2*1000)*pulseDur, delta, pulseDur, pulseShape);

            M0 = [0 0 testCase.Param.M0f testCase.Param.M0r]'; % Initial magnetization, Xf Yf Zf Zr
            
            timeRange = linspace(0, pulseDur, 1000); % in seconds, 10x T2f
            
            for ii =1:length(timeRange)
               M1(ii, :) = BlochSol(timeRange(ii), M0, Param, Pulse1);
               M2(ii, :) = BlochSol(timeRange(ii), M0, Param, Pulse2);
            end
            
            %                          Small FA , Big FA
            testCase.assertGreaterThan(M1(end,3), M2(end,3));
        end
    end
    
end
