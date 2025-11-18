clear all, close all, clc

%% Load Mz before and after for each TR

load('sim2.mat')

%% Plot Mz before and after for each TR

figure()

figure()
plot((1-(Mz_after-delta_Mz_T1relax)./Mz_before)*100)

hold on
plot((1-(M0_remainingTR_free-delta_Mz_T1relax_remaining)./Mz_before)*100)
plot((1-(Mz_after-delta_Mz_T1relax)./Mz_before)*100+(1-(M0_remainingTR_free-delta_Mz_T1relax_remaining)./Mz_before)*100)

legend('MTsat contribution from MT pulse event', 'MTsat contribution from cross-relaxation event', 'Total MTsat for TR')

