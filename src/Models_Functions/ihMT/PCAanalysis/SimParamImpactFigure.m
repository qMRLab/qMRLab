%% Code used to generate the final figure in the paper
%% Be sure to run qMT_PCA_analysis_CorrFactor.m first

% simulation parameters
b1_field = [0.7 0.8 0.9 1 1.1 1.2];
R = [10 26 40];
T2a = [35e-3 60e-3 85e-3];
T1D = [0.0003 0.006 0.013]; % Varma et al., 2017 MRM - 
T2b = [8e-6 12e-6 14e-6]; % Sled and Pike (2001) 
M0b = [0.05 0.1 0.15];
Raobs = [1/0.8 1/1.2 1/1.6];

CF_mat2k = load('/fileDirectory/PCA_output_2k.mat');
CF_mat2k = CF_mat2k.CF_mat;
CF_mat7k = load('//fileDirectory/PCA_output_7k.mat');
CF_mat7k = CF_mat7k.CF_mat;

%% Plot R. 
% extract values for each R from matrix for b1 range. 
param_low_2k = squeeze(CF_mat2k(1,2,2,2,2,2,:));
param_mid_2k = squeeze(CF_mat2k(2,2,2,2,2,2,:));
param_high_2k = squeeze(CF_mat2k(3,2,2,2,2,2,:));

param_low_7k = squeeze(CF_mat7k(1,2,2,2,2,2,:));
param_mid_7k = squeeze(CF_mat7k(2,2,2,2,2,2,:));
param_high_7k = squeeze(CF_mat7k(3,2,2,2,2,2,:));

 figure;
    plot(b1_field, param_low_2k,':','LineWidth',2,'Color',[1 0.5 0.1]);    
    hold on
    plot(b1_field, param_mid_2k,'LineWidth',3,'Color',[0 0 0]);
    plot(b1_field, param_high_2k,':','LineWidth',2,'Color',[1 0.1 0.1]);

    plot(b1_field, param_low_7k,':','LineWidth',2,'Color',[0.1 0.9 1]);
    plot(b1_field, param_mid_7k,'LineWidth',3,'Color',[0.5 0.5 0.5]);
    plot(b1_field, param_high_7k,':','LineWidth',2,'Color',[0.2 0 1]);

        text(0.71,0.9,'k','FontSize', 24, 'FontWeight', 'bold')
        ax = gca;
        ax.FontSize = 20; 
        xlabel('Relative B_1 ', 'FontSize', 20, 'FontWeight', 'bold')
        ylabel('Correction Factor', 'FontSize', 20, 'FontWeight', 'bold')
        legend('2k - k=10s^{-1}' , '2k - k=26s^{-1}' , '2k - k=40s^{-1}', '7k - k=10s^{-1}' ,'7k - k=26s^{-1}' ,'7k - k=40s^{-1}','Location', 'northeast', 'FontSize', 12,'NumColumns', 1)
        xlim([0.7 1.2])
        ylim([-0.3 1]) % for B1 correction comp
    hold off



%% Plot T2a. 
param_low_2k = squeeze(CF_mat2k(2,1,2,2,2,2,:));
param_mid_2k = squeeze(CF_mat2k(2,2,2,2,2,2,:));
param_high_2k = squeeze(CF_mat2k(2,3,2,2,2,2,:));

param_low_7k = squeeze(CF_mat7k(2,1,2,2,2,2,:));
param_mid_7k = squeeze(CF_mat7k(2,2,2,2,2,2,:));
param_high_7k = squeeze(CF_mat7k(2,3,2,2,2,2,:));

 figure;
    plot(b1_field, param_low_2k,':','LineWidth',2,'Color',[1 0.5 0.1]);    
    hold on
    plot(b1_field, param_mid_2k,'LineWidth',3,'Color',[0 0 0]);
    plot(b1_field, param_high_2k,':','LineWidth',2,'Color',[1 0.1 0.1]);

    plot(b1_field, param_low_7k,':','LineWidth',2,'Color',[0.1 0.9 1]);
    plot(b1_field, param_mid_7k,'LineWidth',3,'Color',[0.5 0.5 0.5]);
    plot(b1_field, param_high_7k,':','LineWidth',2,'Color',[0.2 0 1]);

        text(0.71,0.9,'T_{2A}','FontSize', 24, 'FontWeight', 'bold')
        ax = gca;
        ax.FontSize = 20; 
        xlabel('Relative B_1 ', 'FontSize', 20, 'FontWeight', 'bold')
        ylabel('Correction Factor', 'FontSize', 20, 'FontWeight', 'bold')
        xlim([0.7 1.2])
        ylim([-0.3 1]) % for B1 correction comp
        legend('2k - T_{2A}=35 ms' , '2k - T_{2A}=60 ms' , '2k - T_{2A}=85 ms', '7k - T_{2A}=35 ms' ,'7k - T_{2A}=60 ms' ,'7k - T_{2A}=85 ms','Location', 'northeast', 'FontSize', 12,'NumColumns', 1)
    hold off

%% Plot T1D. 
param_low_2k = squeeze(CF_mat2k(2,2,1,2,2,2,:));
param_mid_2k = squeeze(CF_mat2k(2,2,2,2,2,2,:));
param_high_2k = squeeze(CF_mat2k(2,2,3,2,2,2,:));

param_low_7k = squeeze(CF_mat7k(2,2,1,2,2,2,:));
param_mid_7k = squeeze(CF_mat7k(2,2,2,2,2,2,:));
param_high_7k = squeeze(CF_mat7k(2,2,3,2,2,2,:));

 figure;
    plot(b1_field, param_low_2k,':','LineWidth',2,'Color',[1 0.5 0.1]);    
    hold on
    plot(b1_field, param_mid_2k,'LineWidth',3,'Color',[0 0 0]);
    plot(b1_field, param_high_2k,':','LineWidth',2,'Color',[1 0.1 0.1]);

    plot(b1_field, param_low_7k,':','LineWidth',2,'Color',[0.1 0.9 1]);
    plot(b1_field, param_mid_7k,'LineWidth',3,'Color',[0.5 0.5 0.5]);
    plot(b1_field, param_high_7k,':','LineWidth',2,'Color',[0.2 0 1]);

        text(0.71,0.9,'T_{1D}','FontSize', 24, 'FontWeight', 'bold')
        ax = gca;
        ax.FontSize = 20; 
        xlabel('Relative B_1 ', 'FontSize', 20, 'FontWeight', 'bold')
        ylabel('Correction Factor', 'FontSize', 20, 'FontWeight', 'bold')
        xlim([0.7 1.2])
        ylim([-0.3 1]) % for B1 correction comp
        legend('2k - T_{1D}=0.3 ms' , '2k - T_{1D}=6 ms' , '2k - T_{1D}=13 ms', '7k - T_{1D}=0.3 ms' ,'7k - T_{1D}=6 ms' ,'7k - T_{1D}=13 ms','Location', 'northeast', 'FontSize', 12,'NumColumns', 1)
    hold off

%% Plot T2b. 
param_low_2k = squeeze(CF_mat2k(2,2,2,1,2,2,:));
param_mid_2k = squeeze(CF_mat2k(2,2,2,2,2,2,:));
param_high_2k = squeeze(CF_mat2k(2,2,2,3,2,2,:));

param_low_7k = squeeze(CF_mat7k(2,2,2,1,2,2,:));
param_mid_7k = squeeze(CF_mat7k(2,2,2,2,2,2,:));
param_high_7k = squeeze(CF_mat7k(2,2,2,3,2,2,:));

 figure;
    plot(b1_field, param_low_2k,':','LineWidth',2,'Color',[1 0.5 0.1]);    
    hold on
    plot(b1_field, param_mid_2k,'LineWidth',3,'Color',[0 0 0]);
    plot(b1_field, param_high_2k,':','LineWidth',2,'Color',[1 0.1 0.1]);

    plot(b1_field, param_low_7k,':','LineWidth',2,'Color',[0.1 0.9 1]);
    plot(b1_field, param_mid_7k,'LineWidth',3,'Color',[0.5 0.5 0.5]);
    plot(b1_field, param_high_7k,':','LineWidth',2,'Color',[0.2 0 1]);

        text(0.71,0.9,'T_{2B}','FontSize', 24, 'FontWeight', 'bold')
        legend('2k - T_{2B}=8 μs' , '2k - T_{2B}=12 μs' , '2k - T_{2B}=14 μs', '7k - T_{2B}=8 μs' ,'7k - T_{2B}=12 μs' ,'7k - T_{2B}=14 μs','Location', 'northeast', 'FontSize', 12,'NumColumns', 1)
        ax = gca;
        ax.FontSize = 20; 
        xlabel('Relative B_1 ', 'FontSize', 20, 'FontWeight', 'bold')
        ylabel('Correction Factor', 'FontSize', 20, 'FontWeight', 'bold')
        xlim([0.7 1.2])
        ylim([-0.3 1]) % for B1 correction comp
    hold off


%% Plot M0b. 
param_low_2k = squeeze(CF_mat2k(2,2,2,2,1,2,:));
param_mid_2k = squeeze(CF_mat2k(2,2,2,2,2,2,:));
param_high_2k = squeeze(CF_mat2k(2,2,2,2,3,2,:));

param_low_7k = squeeze(CF_mat7k(2,2,2,2,1,2,:));
param_mid_7k = squeeze(CF_mat7k(2,2,2,2,2,2,:));
param_high_7k = squeeze(CF_mat7k(2,2,2,2,3,2,:));

 figure;
    plot(b1_field, param_low_2k,':','LineWidth',2,'Color',[1 0.5 0.1]);    
    hold on
    plot(b1_field, param_mid_2k,'LineWidth',3,'Color',[0 0 0]);
    plot(b1_field, param_high_2k,':','LineWidth',2,'Color',[1 0.1 0.1]);

    plot(b1_field, param_low_7k,':','LineWidth',2,'Color',[0.1 0.9 1]);
    plot(b1_field, param_mid_7k,'LineWidth',3,'Color',[0.5 0.5 0.5]);
    plot(b1_field, param_high_7k,':','LineWidth',2,'Color',[0.2 0 1]);

        text(0.71,0.86,'M_0^B','FontSize', 24, 'FontWeight', 'bold')
        legend('2k - M_0^B=0.05' , '2k - M_0^B=0.1' , '2k - M_0^B=0.15', '7k - M_0^B=0.05' ,'7k - M_0^B=0.1' ,'7k - M_0^B=0.15','Location', 'northeast', 'FontSize', 12,'NumColumns', 1)
        ax = gca;
        ax.FontSize = 20; 
        xlabel('Relative B_1 ', 'FontSize', 20, 'FontWeight', 'bold')
        ylabel('Correction Factor', 'FontSize', 20, 'FontWeight', 'bold')
        xlim([0.7 1.2])
        ylim([-0.3 1]) % for B1 correction comp
    hold off


%% Plot Raobs. 
param_low_2k = squeeze(CF_mat2k(2,2,2,2,2,1,:));
param_mid_2k = squeeze(CF_mat2k(2,2,2,2,2,2,:));
param_high_2k = squeeze(CF_mat2k(2,2,2,2,2,3,:));

param_low_7k = squeeze(CF_mat7k(2,2,2,2,2,1,:));
param_mid_7k = squeeze(CF_mat7k(2,2,2,2,2,2,:));
param_high_7k = squeeze(CF_mat7k(2,2,2,2,2,3,:));

 figure;
    plot(b1_field, param_low_2k,':','LineWidth',2,'Color',[1 0.5 0.1]);    
    hold on
    plot(b1_field, param_mid_2k,'LineWidth',3,'Color',[0 0 0]);
    plot(b1_field, param_high_2k,':','LineWidth',2,'Color',[1 0.1 0.1]);

    plot(b1_field, param_low_7k,':','LineWidth',2,'Color',[0.1 0.9 1]);
    plot(b1_field, param_mid_7k,'LineWidth',3,'Color',[0.5 0.5 0.5]);
    plot(b1_field, param_high_7k,':','LineWidth',2,'Color',[0.2 0 1]);

        text(0.71,0.9,'R_{1,obs}','FontSize', 24, 'FontWeight', 'bold')
        legend('2k - R_{1,obs}=1.25s^{-1}' , '2k - R_{1,obs}=0.833s^{-1}' , '2k - R_{1,obs}=0.625s^{-1}', '7k - R_{1,obs}=1.25s^{-1}' ,'7k - R_{1,obs}=0.833s^{-1}' ,'7k - R_{1,obs}=0.625s^{-1}','Location', 'northeast', 'FontSize', 12,'NumColumns', 1)
        ax = gca;
        ax.FontSize = 20; 
        xlabel('Relative B_1 ', 'FontSize', 20, 'FontWeight', 'bold')
        ylabel('Correction Factor', 'FontSize', 20, 'FontWeight', 'bold')
        xlim([0.7 1.2])
        ylim([-0.3 1]) % for B1 correction comp
    hold off









    
    
    
    
    
    
    
    
    
    
    
