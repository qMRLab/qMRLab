function [M0b_app,fit_qual,comb_res,fitValues] = sampleCode_calc_M0bappVsR1_1dataset(data,MTparams,PDparams,T1params,fitValues,obj)
% Sample code to correlate M0B,app with the R1 values

%fitValues = fitValues.fitValues; % may or maynot need this line depending on how it saves

hfa = data.T1w;
lfa = data.PDw;
mtw = data.MTw;

%% Set up b1 matrices

% B1 nominal and measured -> USER DEFINED
%b1_rms = [6.8];  % value in microTesla. Nominal value for the MTsat pulses
b1_rms = obj.options.CorrelateM0bappVSR1_b1rms; % value in microTesla. Nominal value for the MTsat pulses

b1 = data.B1map;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Brain mask to remove background (optional)
if isfield(data,'Mask') && (~isempty(data.Mask))
    mask = data.Mask;
else
    mask = ones(size(lfa));
end
%mask = zeros(size(lfa)); 
%threshold = 175; % -> USER DEFINED
%mask (lfa >threshold) = 1;  % check your threshold here, data dependent. You could also load a mask made externally instead. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Begin MTsat calculation 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Calculate A0 and R1
low_flip_angle = PDparams(1);   % flip angle in degrees -> USER DEFINED
high_flip_angle = T1params(1);  % flip angle in degrees -> USER DEFINED
TR1 = PDparams(2)*1000;         % low flip angle repetition time of the GRE kernel in milliseconds -> USER DEFINED
TR2 = T1params(2)*1000;         % high flip angle repetition time of the GRE kernel in milliseconds -> USER DEFINED

Inds = find(lfa & hfa & mtw);
MTsat = double(zeros(size(mtw)));

a1 = low_flip_angle*pi/180 .* b1; % note the inclusion of b1 here.
a2 = high_flip_angle*pi/180 .* b1;

% New code Aug 4, 2021 CR for two TR's
R1 = zeros(size(mtw));
App = zeros(size(mtw));
R1(Inds) = 0.5 .* (hfa(Inds).*a2(Inds)./ TR2 - lfa(Inds).*a1(Inds)./TR1) ./ (lfa(Inds)./(a1(Inds)) - hfa(Inds)./(a2(Inds)));
App(Inds) = lfa(Inds) .* hfa(Inds) .* (TR1 .* a2(Inds)./a1(Inds) - TR2.* a1(Inds)./a2(Inds)) ./ (hfa(Inds).* TR1 .*a2(Inds) - lfa(Inds).* TR2 .*a1(Inds));

% Old code for single TR only
%R1 = 0.5 .* (hfa.*a2./ TR - lfa.*a1./TR) ./ (lfa./(a1) - hfa./(a2));
% App = lfa .* hfa .* (TR .* a2./a1 - TR.* a1./a2) ./ (hfa.* TR .*a2 - lfa.* TR .*a1);

R1 = R1.*mask;
T1 = 1./R1.*mask;
App = App.*mask;

%% Generate MTsat maps for the MTw images. 
% Inital Parameters
readout_flip = MTparams(1); % flip angle used in the MTw image, in degrees -> USER DEFINED
TR = MTparams(2)*1000; % -> USER DEFINED
a_MTw_r = readout_flip*pi/180 .* b1;

% calculate maps as per Helms et al 2008. Note: b1 (excitation pulse) is included here for flip angle
MTsat(Inds) = (App(Inds).* (a_MTw_r(Inds))./ mtw(Inds) - ones(size(mtw(Inds)))) .* (R1(Inds)) .* TR - ((a_MTw_r(Inds)).^2)/2;

%fix limits - helps with background noise
MTsat(MTsat<0) = 0;


%% Start with M0B,app fitting  MTsat values 

R1_s = R1*1000; % need to convert to 1/s from 1/ms

% initialize matrices
M0b_app = zeros(size(lfa));
fit_qual = zeros(size(lfa));
comb_res = zeros(size(lfa));


%New code added thanks to Ian Tagge to speed up with the parallel toolbox.
% % accelerate!!!
disp('starting fitting via parfor')

% find indices of valid voxels
q = find( (R1(:)>0));

% make input arrays (length(q),1) from 3D volumes
b1_ = b1(q);
r1s = R1_s(q);
mtsat = MTsat(q);

% allocate output arrays
mob = q.*0; fitq = mob; comb = mob;

if license('test','distrib_computing_toolbox')
    parfor qi = 1:length(q)
        try
             [mob(qi), fitq(qi), comb(qi)] = CR_fit_M0b_v1( b1_rms*b1_(qi), R1_s(qi), mtsat(qi),fitValues.fitValues);
        catch ME
            disp(['qi:' num2str(qi) '; q: ' num2str(q(qi))])
            disp(ME.message)
        end
    end
else

    for qi = 1:length(q)
        try
             [mob(q), fitq(q), comb(q)]  = CR_fit_M0b_v1( b1_rms*b1_(q), R1_s(q), mtsat(q),fitValues.fitValues);
        catch ME
            disp(['qi:' num2str(qi) '; q: ' num2str(q(qi))])
            disp(ME.message)
        end
    end
end

% return output arrays back into 3D volumes
M0b_app(q) = mob;
fit_qual(q) = fitq;
comb_res(q) = comb;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Now make some plots of my fitted maps to see how they correlate with R1 values

R1_p = R1(App>0);
M0b_p = M0b_app(App>0);

plot_con = cat(2, R1_p,M0b_p); 
contrast_fit = zeros(1,2);
ft = fittype('poly1');

% Generate quality Plots
    tmp = plot_con(:,2);
    tmp_r1 = plot_con(:,1)*1000; % convert from ms to sec
    tmp_r1(tmp==0) = []; % to clean up the plots
    tmp(tmp==0) = [];
    M0b_d_fit = fit(tmp_r1,tmp,ft);
    [R,P]= corrcoef([tmp, tmp_r1],'Alpha',0.05,'Rows','complete') ;
    contrast_fit(1,1) = R(2,1);
    contrast_fit(1,2) = P(2,1);
    fitvals_Msat = coeffvalues(M0b_d_fit);
    
    figfit = scatter(tmp_r1,tmp, 1,'.');
    xlim([0.35 1.5])
    ylim([0 0.16])
    hold on
    plot(M0b_d_fit,'fit',0.95);
    caption = sprintf('M_{0,app}^B = %.2g * R_1 %.2g', fitvals_Msat(1), fitvals_Msat(2));
    text(0.45, 0.149, caption, 'FontSize', 16);    
    caption2 = sprintf('r = %.2f', contrast_fit(1,1));
    text(0.78, 0.135, caption2, 'FontSize', 16);
    ax = gca;
    ax.FontSize = 20; 
    xlabel('R_1 (1/s)', 'FontSize', 20, 'FontWeight', 'bold')
    ylabel('M_{0,app}^B', 'FontSize', 20, 'FontWeight', 'bold')
    %colorbar('off')
    legend('hide')
    %saveas(figfit,[obj.options.Sequencesimulation_fitValuesDirectory filesep 'M0bvsR1.png'])
  
    
%% Now add these regression equations to the fitValues structure and save. 
fitValues.fitValues.Est_M0b_from_R1 = strcat( num2str(fitvals_Msat(1)),' *Raobs + ',num2str(fitvals_Msat(2)));
fitValues = fitValues.fitValues;
%fitValue_fn = strcat(obj.options.Sequencesimulation_fitValuesDirectory, filesep, obj.options.Sequencesimulation_fitValuesName);
%save(fitValue_fn,'fitValues')
fitValues.fitValues = fitValues;

end