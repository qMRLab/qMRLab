classdef (TestTags = {'Unit', 'SPGR', 'qMT'}) BlochNoMT_Test < matlab.unittest.TestCase

    properties
    end
    
    methods (TestClassSetup)
    end
    
    methods (TestClassTeardown)
    end
    
    methods (Test)
        function test_no_pulse_mag_remains_unchanged(testCase)
            %% Prep
            %
            delta = 0; % On-resonance
            pulseDur = 0.001; % seconds
            pulseShape = 'hard';
            
            
            flipAngle = 0; % No pulse
            Pulse = GetPulse(flipAngle, delta, pulseDur, pulseShape);
            
            
            T2f = 0.04; % seconds
            M0 = [0 0 1]; % Initial magnetization, XYZ
            
            timeRange = linspace(0,10,1000); % in seconds
            
            [~,M]=ode23(@(t,M) BlochNoMT(t, M, T2f, Pulse), timeRange, M0);
            
            
            %                    Actual ,  Expected
            testCase.assertEqual(M(end,:), M0);
        end
        
        function test_90_deg_pulse_rotates_to_transverse_for_inf_t2f(testCase)
            %% Prep
            %
            delta = 0; % On-resonance
            pulseDur = 0.001; % seconds, near-instantaneous
            pulseShape = 'hard';
            
            
            flipAngle = 90; % Assume a pulse that gives 90 deg per milliseconds, and calculate the FA for 10 seconds
            Pulse = GetPulse(flipAngle, delta, pulseDur, pulseShape);
            
            %***
            T2f = inf; % Ignore T2f for this ideal case
            %***

            M0 = [0 0 1]; % Initial magnetization, XYZ
            
            timeRange = linspace(0, pulseDur,1000); % in seconds, verify end of pulse
            
            [~,M]=ode23(@(t,M) BlochNoMT(t, M, T2f, Pulse), timeRange, M0);
            
            %                    Actual ,  Expected
            testCase.assertEqual(M(end,:), [0 1 0], 'AbsTol', 0.01);
        end
        
        function test_180_deg_pulse_rotates_to_transverse_for_inf_t2f(testCase)
            %% Prep
            %
            delta = 0; % On-resonance
            pulseDur = 0.001; % seconds, near-instantaneous
            pulseShape = 'hard';
            
            
            flipAngle = 180; % Assume a pulse that gives 90 deg per milliseconds, and calculate the FA for 10 seconds
            Pulse = GetPulse(flipAngle, delta, pulseDur, pulseShape);
            
            %***
            T2f = inf; % Ignore T2f for this ideal case
            %***
            
            M0 = [0 0 1]; % Initial magnetization, XYZ
            
            timeRange = linspace(0, pulseDur,1000); % in seconds, verify end of pulse
            
            [~,M]=ode23(@(t,M) BlochNoMT(t, M, T2f, Pulse), timeRange, M0);
            
            %                    Actual ,  Expected
            testCase.assertEqual(M(end,:), [0 0 -1], 'AbsTol', 0.01);
        end
        
        function test_no_longi_mag_evol_for_transverse_inital_mag_inf_t2f(testCase)
            %% Prep
            %
            delta = 100; % Go to the rotating ref frame for this case
            pulseDur = 0.001; % seconds, near-instantaneous
            pulseShape = 'hard';
            
            
            flipAngle = 0; % Assume a pulse that gives 90 deg per milliseconds, and calculate the FA for 10 seconds
            Pulse = GetPulse(flipAngle, delta, pulseDur, pulseShape);
            
            %***
            T2f = inf; % Ignore T2f for this ideal case
            %***
            
            M0 = [1 0 0]; % Initial magnetization, XYZ
            
            timeRange = linspace(0, 1, 1000); % in seconds
            
            [~,M]=ode23(@(t,M) BlochNoMT(t, M, T2f, Pulse), timeRange, M0);
            
            %                    Actual ,  Expected
            testCase.assertEqual(M(end,3), 0);
        end
        
        function test_mag_goes_to_zero_for_time_much_greater_than_t2f(testCase)
            %% Prep
            %
            delta = 100; % Go to the rotating ref frame for this case
            pulseDur = 0.001; % seconds, near-instantaneous
            pulseShape = 'hard';
            
            
            flipAngle = 0; % Assume a pulse that gives 90 deg per milliseconds, and calculate the FA for 10 seconds
            Pulse = GetPulse(flipAngle, delta, pulseDur, pulseShape);
            
            %***
            T2f = 0.04; % Ignore T2f for this ideal case
            %***
            
            M0 = [1 0 0]; % Initial magnetization, XYZ
            
            timeRange = linspace(0, 10*T2f, 1000); % in seconds, 10x T2f
            
            [~,M]=ode23(@(t,M) BlochNoMT(t, M, T2f, Pulse), timeRange, M0);
            
            %                    Actual ,  Expected
            testCase.assertEqual(M(end,:), 0*M0, 'AbsTol', 0.001);
        end
    end
    
end