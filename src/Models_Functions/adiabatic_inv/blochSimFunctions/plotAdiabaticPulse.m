function plotAdiabaticPulse(t, inv_pulse, A_t, omega1, Params)


%% Adiabatic Pulse Plot function 
%
% Called in  adiabativ_inv (qMRLab) and adiabaticExample.m to check the 
% amplitude, frequency and phase modulation of your pulse 
%
%   inv_pulse denotes the adiabatic inversion pulse and can be found from
%   the individual pulse functions listed in getAdiabaticPulse.m 
%
% Written by Amie Demmans 2024
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fs = 18; 
figure; 
tiledlayout(1,3)

% Plot Amplitude Function
    nexttile;
    plot(t, A_t, 'LineWidth', 3); 
    xlabel('T_{rf} (ms)'); 
    ylabel('B_1 (μT)');
    title('Amplitude Modulation','FontWeight','normal');
    ax = gca; 
    ax.FontSize = fs;

% Plot Frequency Modulation Function
    nexttile; 
    plot(t, omega1, 'LineWidth', 3);
    xlabel('T_{rf} (ms)'); 
    ylabel('Frequency (Hz)');
    title('Frequency Modulation','FontWeight','normal');
    ax = gca; 
    ax.FontSize = fs;

 % Plot Phase Modulation Function 
    nexttile; 
    plot(t, imag(inv_pulse), 'LineWidth', 3);
    xlabel('T_{rf} (ms)'); 
    ylabel('Frequency (Hz)');
    title('Phase Modulation', 'FontWeight','normal');
    ax = gca; 
    ax.FontSize = fs;

% Scale display size     
set(gcf,'Position',[100 100 1200 500])

% Set title of pulse 
sgtitle(Params.shape, 'FontSize', fs+4,'FontWeight','bold')