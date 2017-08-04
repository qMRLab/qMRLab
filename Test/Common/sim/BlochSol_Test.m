classdef (TestTags = {'Unit', 'SPGR', 'qMT'}) BlochSol_Test < matlab.unittest.TestCase

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
            testCase.assertEqual(double(M(end,:)), M0', 'AbsTol', 0.001);
        end
        
        function test_no_longi_mag_evol_for_transverse_inital_mag_inf_t2_t1(testCase)
            %% Prep
            %
            Param = testCase.Param;
            
            delta = 100; % Go to the rotating ref frame for this case
            Param.G = computeG(delta,1/Param.R2f, 'SuperLorentzian');

            pulseDur = 0.001; % seconds, near-instantaneous
            pulseShape = 'hard';
            
            
            flipAngle = 0; % Assume a pulse that gives 90 deg per milliseconds, and calculate the FA for 10 seconds
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
            
            %                    Actual ,  Expected
            testCase.assertEqual(double(M(end,3)), M0(3), 'AbsTol', 0.001);
        end
        
        function test_magn_evols_to_equilibrium_vals(testCase)
            %% Prep
            %
            Param = testCase.Param;
            
            delta = 100; % Go to the rotating ref frame for this case
            Param.G = computeG(delta,1/Param.R2f, 'SuperLorentzian');

            pulseDur = 0.001; % seconds, near-instantaneous
            pulseShape = 'hard';
            
            
            flipAngle = 0; % Assume a pulse that gives 90 deg per milliseconds, and calculate the FA for 10 seconds
            Pulse = GetPulse(flipAngle, delta, pulseDur, pulseShape);
            
            M0 = [0 0 0 0]'; % Initial magnetization, Xf Yf Zf Zr
            
            timeRange = linspace(0, (1/Param.R1f*10), 1000); % in seconds, 10x T1f
            
            for ii =1:length(timeRange)
               M(ii, :) = BlochSol(timeRange(ii), M0, Param, Pulse);
            end
            
            %                    Actual ,  Expected
            testCase.assertEqual(double(M(end,:)), [0 0 Param.M0f Param.M0r], 'AbsTol', 0.001);
        end
        
        function test_mag_goes_to_zero_for_time_much_greater_than_t2f(testCase)            %% Prep
            %% Prep
            %
            Param = testCase.Param;
            
            delta = 100; % Go to the rotating ref frame for this case
            Param.G = computeG(delta,1/Param.R2f, 'SuperLorentzian');

            pulseDur = 0.001; % seconds, near-instantaneous
            pulseShape = 'hard';
            
            
            flipAngle = 0; % Assume a pulse that gives 90 deg per milliseconds, and calculate the FA for 10 seconds
            Pulse = GetPulse(flipAngle, delta, pulseDur, pulseShape);
            
            M0 = [1 0 0 0]'; % Initial magnetization, Xf Yf Zf Zr
            
            timeRange = linspace(0, (1/Param.R2f)*10, 1000); % in seconds, 10x T2f
            
            for ii =1:length(timeRange)
               M(ii, :) = BlochSol(timeRange(ii), M0, Param, Pulse);
            end
            
            %                    Actual ,  Expected
            testCase.assertEqual(double(M(end,1:2)), [0 0], 'AbsTol', 0.001);
        end
    end
    
end