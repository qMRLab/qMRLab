clear all, close all, clc

%% Load Mz before and after for each TR

load('sim2.mat')

%% Plot Mz before and after for each TR

figure()
plot(Mz_before, 'r')
hold on
plot(Mz_after, 'b')
legend('Mz_{before}', 'Mz_{after}')

figure()
plot(Mz_before(end-10+1:end), 'r')
hold on
plot(Mz_after(end-10+1:end), 'b')
legend('Mz_{before}', 'Mz_{after}')

figure()
plot(1-Mz_after./Mz_before)
legend('1-Mz_{after}/Mz_{before}')

figure()
plot((1-Mz_after./Mz_before)*100)
legend('1-Mz_{after}/Mz_{before}')
