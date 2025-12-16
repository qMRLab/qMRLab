clc; clear; close all;

alpha1 = deg2rad(5);  % Flip angle for first VFA block (radians)
alpha2 = deg2rad(5);  % Flip angle for second VFA block (radians)
N_VFA1 = 50;         % Number of excitations in first VFA block
N_VFA2 = 50;         % Number of excitations in second VFA block
TI1 = 700;            % First inversion time (ms)
TI2 = 2500;           % Second inversion time (ms)
T1 = 1000;            % Longitudinal relaxation time (ms)
T2 = 80;              % Transverse relaxation time (ms)
TE = 5;               % Echo time (ms)
TR = 5000;            % Repetition time (ms)
df = 0;               % Off-resonance frequency (Hz)
inc = 0;              % RF phase increment (degrees)

[MLong_TI1, MLong_TI2, Msig1, Msig2] = mp2rage_blochsim(alpha1, alpha2, N_VFA1, N_VFA2, TI1, TI2, T1, T2, TE, TR, df, inc);

t_TI1 = TI1;
t_TI2 = TI2;
t_VFA1 = linspace(t_TI1, t_TI1 + N_VFA1 * 2 * TE, N_VFA1);
t_VFA2 = linspace(t_TI2, t_TI2 + N_VFA2 * 2 * TE, N_VFA2);
t_TR = TR;

t_curve = linspace(0, TR, 1000);
Mz_recovery = 1 - 2 * exp(-t_curve/T1);

figure;
subplot(2,1,1);
hold on;
plot(t_curve, Mz_recovery, '--', 'LineWidth', 1.5)
plot(t_TI1, MLong_TI1, 'b+', 'MarkerSize', 8, 'LineWidth', 2);
plot(t_TI2, MLong_TI2, 'r+', 'MarkerSize', 8, 'LineWidth', 2);
xlabel('Time (ms)');
ylabel('M_z');
ylim([-1,1])
xlim([0,TR])
legend('T1 Recovery (Expected)','Before First VFA Block (TI1)', 'Before Second VFA Block (TI2)', Location='best');
title('Longitudinal Magnetization Before VFA Blocks');
grid on;

subplot(2,1,2);
hold on;
plot(t_VFA1, abs(Msig1), 'b-', 'LineWidth', 2, 'MarkerSize', 8);
plot(t_VFA2, abs(Msig2), 'r-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('Time (ms)');
ylabel('|M_{xy}|');
ylim([-1,1])
xlim([0,TR])
legend('First VFA Block', 'Second VFA Block', Location='best');
title('Transverse Magnetization at TE');
grid on;
