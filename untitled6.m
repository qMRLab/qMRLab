close all
clear all
clc
% Parameters
Tp = 3e-3; % Pulse duration in seconds
N = 2048; % Number of samples
dt = Tp / N; % Time step
gamma = 42.58e6; % Gyromagnetic ratio in Hz/T
B0 = 1.5; % Main magnetic field strength in Tesla
g = 0.01; % Gradient strength in T/m

% Define flip angle
flip_angle = 120; % Degrees

% Time vector for RF pulse
t = linspace(-Tp/2, Tp/2, N);

% Define sinc RF pulse
RF_pulse = sinc(t / (Tp/10)); % Sinc pulse

% Normalize RF pulse for large flip angle
alpha = flip_angle * pi / 180; % Convert to radians
B1_max = alpha / (gamma * sum(RF_pulse) * dt); % Max B1 field
RF_pulse = B1_max * RF_pulse; % Scale pulse

% Calculate the slice profile using Bloch simulation
% Initialize magnetization components
M_x = zeros(1, N);
M_y = zeros(1, N);
M_z = ones(1, N); % Initially, Mz = 1 (longitudinal magnetization)

% Bloch equation simulation
for i = 2:N
    % Apply RF pulse
    B1 = RF_pulse(i);
    % Bloch equations
    M_x(i) = M_z(i-1) * sin(B1);
    M_y(i) = M_y(i-1) * cos(B1);
    M_z(i) = M_z(i-1) * cos(B1) - M_x(i-1) * sin(B1);
end

% The first value of M_x and M_y should be set to zero for consistent results
M_x(1) = 0;
M_y(1) = 0;

% Compute the slice profile (Fourier transform of the resulting Mx)
slice_profile = abs(fftshift(fft(M_x)));

% Frequency axis corresponding to the Fourier transform
freq_axis = linspace(-1/(2*dt), 1/(2*dt), N);

% Plotting
figure;

% Subplot 1: RF pulse shape
subplot(2,1,1);
plot(t, RF_pulse);
title('RF Pulse Shape');
xlabel('Time (s)');
ylabel('Amplitude (a.u.)');
grid on;

% Subplot 2: Slice profile (Bloch simulation result)
subplot(2,1,2);
plot(freq_axis, slice_profile);
title(['Slice Profile for ' num2str(flip_angle) '° RF Pulse']);
xlabel('Frequency (Hz)');
ylabel('Magnitude (a.u.)');
xlim([-2000, 2000]); % Expanded frequency range for better visualization
grid on;
