function [fitValues, MTsat_sim] = simSeq_M0b_R1obs(obj,SimProt,M0b,T1obs)
%% Simulate sequence and generate fitequation to cover the spectrum of MTsat
% results for varying B1rms, R1obs and M0b. 

% This script can take ~ 3 hours to run. 
%% Set the variables to loop over
Raobs = 1./T1obs;
b1rms = SimProt.b1; %b1rms of one of the applied MT pulse in microTesla -> USER DEFINED
% generate b1 vector
b1 = linspace(0,b1rms*1.3,15); 

%% Sequence Parameters -> USER DEFINED SECTION
% values of the Sequence Simulation
Params = SimProt;

%% Run the simulation
GRE_sig = zeros(size(b1,2),size(M0b,2),size(Raobs,2));
R1app = zeros(size(M0b,2),size(Raobs,2));
Aapp = zeros(size(M0b,2),size(Raobs,2));

tic
for i = 1:size(b1,2) % took nearly 5 hours for matrix 25x41x33.
    Params.b1 = b1(i);

    for j = 1:size(M0b,2)
        Params.M0b = M0b(j);
        
        for k = 1:size(Raobs,2)
            Params.Raobs = Raobs(k);
            GRE_sig(i,j,k) = MAMT_model_2007_5(Params);
            
            if i == 1
                [R1app(j,k), Aapp(j,k)] = MAMT_model_simVFA(Params); % save time only doing this for tissue parameters
            end
            
        end
    end
    i/size(b1,2) *100  % print percent done...
    toc
end
Params.b1 = b1rms;
Params.M0b = M0b;
Params.Raobs = Raobs;

%% MTsat calculation
%reformat Aapp and R1app matrices for 3D calculation
Aapp_vfa = repmat(Aapp,[1,1,size(b1,2)]);
Aapp_vfa = permute(Aapp_vfa,[3,1,2]);
R1app_vfa = repmat(R1app,[1,1,size(b1,2)]);
R1app_vfa = permute(R1app_vfa,[3,1,2]);

flip_rad = Params.flipAngle*pi/180 ; % use the nominal value here 
MTsat_sim = (Aapp_vfa * flip_rad ./ GRE_sig - 1) .* R1app_vfa .* Params.TR - (flip_rad.^2)/2;

%% Fit a 3rd degree polynomial to the tc-B1-T1B interaction. Fit 3rd degree polynomial (tricubic interpolation)
% solve using poltfitn toolbox https://www.mathworks.com/matlabcentral/fileexchange/34765-polyfitn
% and get equation from https://www.mathworks.com/matlabcentral/fileexchange/9577-symbolic-polynomial-manipulation

[ M0b_mesh,b1_mesh,Raobs_mesh] = meshgrid(M0b',b1',Raobs'); % note: meshgrid swaps the first two dimensions, so we enter reverse order. 
M0b_l = M0b_mesh(:); % convert to 1x vector for fitting
b1_l = b1_mesh(:);
Raobs_l = Raobs_mesh(:);
fitz = MTsat_sim(:);

%fitz(isinf(fitz)) = 0; % should change this to a remove, shouldnt be a problem with next iteration. Likely due to putting flip angle = flip*b1.

% Generate the tricubic model. 
modelTerms = zeros(64,3);
idx = 1;
for i = 0:3
    for j = 0:3
        for k = 0:3
            modelTerms(idx,1) = i;
            modelTerms(idx,2) = j;
            modelTerms(idx,3) = k;
            idx = idx+1;
        end
    end
end


tic
fit_SSsat = polyfitn([M0b_l, b1_l, Raobs_l], fitz, modelTerms); % ~ 5 seconds. 
toc

fit_SSsat.VarNames = {'M0b','b1','Raobs'}; % these will be the variable names required to evaluate them

% % write out equation
fit_SS_eqn = strcat( num2str(fit_SSsat.Coefficients(1)),' + ',num2str(fit_SSsat.Coefficients(2)),'*Raobs + ',num2str(fit_SSsat.Coefficients(3)),'*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(4)),'*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(5)),'*b1 + ',num2str(fit_SSsat.Coefficients(6)),'*b1.*Raobs + ',num2str(fit_SSsat.Coefficients(7)),'*b1.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(8)),'*b1.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(9)),'*b1.^2 + ',num2str(fit_SSsat.Coefficients(10)),'*b1.^2.*Raobs + ',num2str(fit_SSsat.Coefficients(11)),'*b1.^2.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(12)),'*b1.^2.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(13)),'*b1.^3 + ',num2str(fit_SSsat.Coefficients(14)),'*b1.^3.*Raobs + ',num2str(fit_SSsat.Coefficients(15)),'*b1.^3.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(16)),'*b1.^3.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(17)),'*M0b + ',num2str(fit_SSsat.Coefficients(18)),'*M0b.*Raobs + ',num2str(fit_SSsat.Coefficients(19)),'*M0b.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(20)),'*M0b.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(21)),'*M0b.*b1 + ',num2str(fit_SSsat.Coefficients(22)),'*M0b.*b1.*Raobs + ',num2str(fit_SSsat.Coefficients(23)),'*M0b.*b1.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(24)),'*M0b.*b1.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(25)),'*M0b.*b1.^2 + ',num2str(fit_SSsat.Coefficients(26)),'*M0b.*b1.^2.*Raobs + ',num2str(fit_SSsat.Coefficients(27)),'*M0b.*b1.^2.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(28)),'*M0b.*b1.^2.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(29)),'*M0b.*b1.^3 + ',num2str(fit_SSsat.Coefficients(30)),'*M0b.*b1.^3.*Raobs + ',num2str(fit_SSsat.Coefficients(31)),'*M0b.*b1.^3.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(32)),'*M0b.*b1.^3.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(33)),'*M0b.^2 + ',num2str(fit_SSsat.Coefficients(34)),'*M0b.^2.*Raobs + ',num2str(fit_SSsat.Coefficients(35)),'*M0b.^2.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(36)),'*M0b.^2.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(37)),'*M0b.^2.*b1 + ',num2str(fit_SSsat.Coefficients(38)),'*M0b.^2.*b1.*Raobs + ',num2str(fit_SSsat.Coefficients(39)),'*M0b.^2.*b1.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(40)),'*M0b.^2.*b1.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(41)),'*M0b.^2.*b1.^2 + ',num2str(fit_SSsat.Coefficients(42)),'*M0b.^2.*b1.^2.*Raobs + ',num2str(fit_SSsat.Coefficients(43)),'*M0b.^2.*b1.^2.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(44)),'*M0b.^2.*b1.^2.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(45)),'*M0b.^2.*b1.^3 + ',num2str(fit_SSsat.Coefficients(46)),'*M0b.^2.*b1.^3.*Raobs + ',num2str(fit_SSsat.Coefficients(47)),'*M0b.^2.*b1.^3.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(48)),'*M0b.^2.*b1.^3.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(49)),'*M0b.^3 + ',num2str(fit_SSsat.Coefficients(50)),'*M0b.^3.*Raobs + ',num2str(fit_SSsat.Coefficients(51)),'*M0b.^3.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(52)),'*M0b.^3.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(53)),'*M0b.^3.*b1 + ',num2str(fit_SSsat.Coefficients(54)),'*M0b.^3.*b1.*Raobs + ',num2str(fit_SSsat.Coefficients(55)),'*M0b.^3.*b1.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(56)),'*M0b.^3.*b1.*Raobs.^3',... 
' + ',num2str(fit_SSsat.Coefficients(57)),'*M0b.^3.*b1.^2 + ',num2str(fit_SSsat.Coefficients(58)),'*M0b.^3.*b1.^2.*Raobs + ',num2str(fit_SSsat.Coefficients(59)),'*M0b.^3.*b1.^2.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(60)),'*M0b.^3.*b1.^2.*Raobs.^3',...
' + ',num2str(fit_SSsat.Coefficients(61)),'*M0b.^3.*b1.^3 + ',num2str(fit_SSsat.Coefficients(62)),'*M0b.^3.*b1.^3.*Raobs + ',num2str(fit_SSsat.Coefficients(63)),'*M0b.^3.*b1.^3.*Raobs.^2 + ',num2str(fit_SSsat.Coefficients(64)),'*M0b.^3.*b1.^3.*Raobs.^3');

% Equation to be filled with Raobs later... 
fit_SS_eqn_sprintf = strcat( num2str(fit_SSsat.Coefficients(1)),' + ',num2str(fit_SSsat.Coefficients(2)),'*(%f) + ',num2str(fit_SSsat.Coefficients(3)),'*(%f).^2 + ',num2str(fit_SSsat.Coefficients(4)),'*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(5)),'*b1 + ',num2str(fit_SSsat.Coefficients(6)),'*b1.*(%f) + ',num2str(fit_SSsat.Coefficients(7)),'*b1.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(8)),'*b1.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(9)),'*b1.^2 + ',num2str(fit_SSsat.Coefficients(10)),'*b1.^2.*(%f) + ',num2str(fit_SSsat.Coefficients(11)),'*b1.^2.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(12)),'*b1.^2.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(13)),'*b1.^3 + ',num2str(fit_SSsat.Coefficients(14)),'*b1.^3.*(%f) + ',num2str(fit_SSsat.Coefficients(15)),'*b1.^3.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(16)),'*b1.^3.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(17)),'*M0b + ',num2str(fit_SSsat.Coefficients(18)),'*M0b.*(%f) + ',num2str(fit_SSsat.Coefficients(19)),'*M0b.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(20)),'*M0b.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(21)),'*M0b.*b1 + ',num2str(fit_SSsat.Coefficients(22)),'*M0b.*b1.*(%f) + ',num2str(fit_SSsat.Coefficients(23)),'*M0b.*b1.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(24)),'*M0b.*b1.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(25)),'*M0b.*b1.^2 + ',num2str(fit_SSsat.Coefficients(26)),'*M0b.*b1.^2.*(%f) + ',num2str(fit_SSsat.Coefficients(27)),'*M0b.*b1.^2.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(28)),'*M0b.*b1.^2.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(29)),'*M0b.*b1.^3 + ',num2str(fit_SSsat.Coefficients(30)),'*M0b.*b1.^3.*(%f) + ',num2str(fit_SSsat.Coefficients(31)),'*M0b.*b1.^3.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(32)),'*M0b.*b1.^3.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(33)),'*M0b.^2 + ',num2str(fit_SSsat.Coefficients(34)),'*M0b.^2.*(%f) + ',num2str(fit_SSsat.Coefficients(35)),'*M0b.^2.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(36)),'*M0b.^2.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(37)),'*M0b.^2.*b1 + ',num2str(fit_SSsat.Coefficients(38)),'*M0b.^2.*b1.*(%f) + ',num2str(fit_SSsat.Coefficients(39)),'*M0b.^2.*b1.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(40)),'*M0b.^2.*b1.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(41)),'*M0b.^2.*b1.^2 + ',num2str(fit_SSsat.Coefficients(42)),'*M0b.^2.*b1.^2.*(%f) + ',num2str(fit_SSsat.Coefficients(43)),'*M0b.^2.*b1.^2.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(44)),'*M0b.^2.*b1.^2.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(45)),'*M0b.^2.*b1.^3 + ',num2str(fit_SSsat.Coefficients(46)),'*M0b.^2.*b1.^3.*(%f) + ',num2str(fit_SSsat.Coefficients(47)),'*M0b.^2.*b1.^3.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(48)),'*M0b.^2.*b1.^3.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(49)),'*M0b.^3 + ',num2str(fit_SSsat.Coefficients(50)),'*M0b.^3.*(%f) + ',num2str(fit_SSsat.Coefficients(51)),'*M0b.^3.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(52)),'*M0b.^3.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(53)),'*M0b.^3.*b1 + ',num2str(fit_SSsat.Coefficients(54)),'*M0b.^3.*b1.*(%f) + ',num2str(fit_SSsat.Coefficients(55)),'*M0b.^3.*b1.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(56)),'*M0b.^3.*b1.*(%f).^3',... 
' + ',num2str(fit_SSsat.Coefficients(57)),'*M0b.^3.*b1.^2 + ',num2str(fit_SSsat.Coefficients(58)),'*M0b.^3.*b1.^2.*(%f) + ',num2str(fit_SSsat.Coefficients(59)),'*M0b.^3.*b1.^2.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(60)),'*M0b.^3.*b1.^2.*(%f).^3',...
' + ',num2str(fit_SSsat.Coefficients(61)),'*M0b.^3.*b1.^3 + ',num2str(fit_SSsat.Coefficients(62)),'*M0b.^3.*b1.^3.*(%f) + ',num2str(fit_SSsat.Coefficients(63)),'*M0b.^3.*b1.^3.*(%f).^2 + ',num2str(fit_SSsat.Coefficients(64)),'*M0b.^3.*b1.^3.*(%f).^3');


% put into one variable for export
fitValues.fitvals_coeff = fit_SSsat.Coefficients;
fitValues.fit_SS_eqn = fit_SS_eqn;
fitValues.fit_SS_eqn_sprintf = fit_SS_eqn_sprintf;
fitValues.Params = Params; % export params to reference later if desired

%check fit

M0b =  M0b_mesh;
b1 = b1_mesh;
Raobs = Raobs_mesh;

z = eval(fit_SS_eqn);

% max(max(max( z - MTsat_sim   )))
% min(min(min( z - MTsat_sim   )))

% save the fit values for use based on filenames
fitValue_fn = strcat(obj.options.Sequencesimulation_fitValuesDirectory, filesep, obj.options.Sequencesimulation_fitValuesName, '.mat'); % location and name of fitValues file to be saved
MTsatValue_fn = strcat(obj.options.Sequencesimulation_fitValuesDirectory, filesep, obj.options.Sequencesimulation_MTsatValuesName, '.mat'); %save the computationally expensive results, incase fit needs to be adjusted

save(fitValue_fn,'fitValues')
save(MTsatValue_fn,'MTsat_sim')



%% Generate figure to show result at T1 = 1000ms;
slice = 9;
slice_b1 = squeeze(b1_mesh(:,:,slice));
slice_M0b = squeeze(M0b_mesh(:,:,slice));
slice_MT = squeeze(MTsat_sim(:,:,slice));
slice_z = squeeze(z(:,:,slice));


figure;
surf(slice_b1, slice_M0b, slice_MT)
hold on
surf(slice_b1, slice_M0b, slice_z)
ax = gca;
ax.FontSize = 16; 
xlabel('B_1 (\muT)', 'FontSize', 16, 'FontWeight', 'bold')
ylabel('M_{0b}', 'FontSize', 16, 'FontWeight', 'bold')
zlabel('MT_{sat}', 'FontSize', 16, 'FontWeight', 'bold')
%legend('sim','meas')

end





