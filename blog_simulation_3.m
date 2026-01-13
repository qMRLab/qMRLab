clear all, close all, clc

%% Load Mz before and after for each TR

load('sim2.mat')

%% Plot Mz before and after for each TR

figure()

figure()
plot((1-Mz_after./Mz_before)*100)
hold on
plot((1-(Mz_after-delta_Mz_T1relax)./Mz_before)*100)

legend('MTsat before T1 correction', 'MTsat after T1 correction')

figure()
plot((1-(Mz_after-delta_Mz_T1relax)./Mz_before)*100)
legend('1-Mz_{after}/Mz_{before}')
