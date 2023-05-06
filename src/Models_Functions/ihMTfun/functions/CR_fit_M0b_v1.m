function [M0b, maskval, comb_resid]= CR_fit_M0b_v1(B1_ref,Raobs, msat,fitValues)

% we have 4 data points for saturation level for dual saturation
% each point is collected at a set B1 value and achieves a saturation level

% B1_ref -> contains the x data points. Take the relative B1map and multiply by the nominal B1 values
% Raobs -> is the measured R1 map, from VFA 
% msat -> is the Y data points to fit. MTsat values for each of the X points. 
% fitValues -> is derived from "simWith_M0b_R1obs.m" script

% Exports:
% M0b is the fit value for M0b
% maskval is a mask to signify poor fit regions
% comb_resid == the summation of the residuals from all fit points. 

% %Debugging test parameters
% i = 64; j = 66; k = 46; % Genu of Corpus Callosum for paper.
% % fitValues = fitValues_dual;
% % B1_ref = squeeze(b1_comb_scaled(i,j,k,:)) % this should give us 4 data points
% % msat = squeeze(dual_s(i,j,k,:)) % test values for "z"
% Raobs = R1_s(i,j,k)
% 
% fitValues = fitValues2k;
% B1_ref = squeeze(b1_3p26(i,j,k,:)) % this should give us 4 data points
% msat = msat_irl_2k(i,j,k) % test values for "z"



maskval = 0;

if (min(msat) == 0) || (max(isnan(msat)) > 0) % fit will be poor
    M0b = 0; 
    maskval = 1; % just generate a mask to note regions which might have a bad fit. 
    comb_resid = 0;
    return;
end

fit_eqn = fitValues.fit_SS_eqn_sprintf;
% need to insert the Raobs values:
fit_eqn = sprintf(fit_eqn, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs...
               , Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs...
               , Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs...
               , Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs...
               , Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs...
               , Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs, Raobs);


opts = fitoptions( 'Method', 'NonlinearLeastSquares','Upper',0.5,'Lower',0.0,'StartPoint',0.1);
opts.Robust = 'Bisquare';

myfittype = fittype( fit_eqn ,'dependent', {'z'}, 'independent',{'b1'},'coefficients', {'M0b'}); 
fitpos = fit(B1_ref, msat, myfittype,opts);
fitvals = coeffvalues(fitpos);

M0b = fitvals(1);

%% Calculate Residuals
% solve the equation for the 
comb_resid = 0;
for i = 1:size(msat,1)
    b1 = B1_ref(i);
    tmp = eval(fit_eqn);
    resid = abs(tmp - msat(i));
    comb_resid = comb_resid + resid;
end


 
%% you can plot to check the fit
% b1_ref = 0:0.25:11;
% msat_calc = fitpos(b1_ref);
% figure;
% plot(b1_ref,msat_calc,'LineWidth',2)
% hold on
% scatter(B1_ref, msat,40,'filled')
%     ax = gca;
%     ax.FontSize = 20; 
%     xlabel('B_{1RMS} (\muT) ', 'FontSize', 20, 'FontWeight', 'bold')
%     ylabel('MT_{sat}', 'FontSize', 20, 'FontWeight', 'bold')
%      %   colorbar('off')
%     legend('hide')
%     text(6.2, 0.0015, strcat('M_{0,app}^B = ',num2str(M0b,'%.3g')), 'FontSize', 16); 
%     ylim([-0.001 20e-3])

    
    
   %% 2k code. 
    
%   b1_ref = 0:0.25:5;
% msat_calc = fitpos(b1_ref);
% figure;
% plot(b1_ref,msat_calc,'LineWidth',2)
% hold on
% scatter(B1_ref, msat,40,'filled')
%     ax = gca;
%     ax.FontSize = 20; 
%     xlabel('B_{1RMS} (\muT) ', 'FontSize', 20, 'FontWeight', 'bold')
%     ylabel('MT_{sat}', 'FontSize', 20, 'FontWeight', 'bold')
%      %   colorbar('off')
%     legend('hide')
%     text(2.2, 0.0015, strcat('M_{0,app}^B = ',num2str(M0b,'%.3g')), 'FontSize', 16); 
%     ylim([-0.001 25e-3])  
    
    
    
    
    
    
    
    
    
    
    
    

