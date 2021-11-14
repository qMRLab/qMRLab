% the goal of this is to suggest that the majority of the variance in the 
% correction factor space can be attributed to one variable.  
% to do this, generate CF's for a range of tissue parameters, forming a
% matrix of CF values. 

% Specify output location
% note to change name if running with another sequence setup.
outputPCAmatrix = '/fileDirectory/PCA_output.m';


%% Sequence Parameters
Params.b1 = 0; % microTesla
Params.pulseGapDur = 0.6/1000; %ms gap between MT pulses in train
Params.TR = 28/1000; % total repetition time = MT pulse train and readout.
Params.WExcDur = 3/1000; % duration of water pulse
Params.numExcitation = 1; % number of readout lines/TR
Params.flipAngle = 9; % excitation flip angle water.

%% Two runs were done, select the one you want, and comment out the other
% Params.numSatPulse = 1;
% Params.pulseDur = 12/1000; %duration of 1 MT pulse in seconds
% B1 = 3.26; % in microtesla
% Params.delta = 2000;
% Params.freqPattern = 'single'; % options: 'single', 'dualAlternate', 'dualContinuous'
% Params.SatPulseShape = 'gaussian'; % options: 'hanning', 'gaussian', 'square'

Params.numSatPulse = 2;
Params.pulseDur = 0.768/1000; %duration of 1 MT pulse in seconds
Params.freqPattern = 'single'; % options: 'single', 'dualAlternate', 'dualContinuous'
Params.delta = 7000;
B1 = 8.5; % in microtesla
Params.SatPulseShape = 'hanning'; % options: 'hanning', 'gaussian', 'square'


% simulation parameters
b1_field = [0.7 0.8 0.9 1 1.1 1.2];
R = [10 26 40];
T2a = [35e-3 60e-3 85e-3];
T1D = [0.0003 0.006 0.013]; % Varma et al., 2017 MRM - 
T2b = [8e-6 12e-6 14e-6]; % Sled and Pike (2001) 
M0b = [0.05 0.1 0.15];
Raobs = [1/0.8 1/1.2 1/1.6];


% Fixed Variables
Params.lineshape = 'superLor'; % or 'superLor';
Params.M0a = 1;
Params.Rb = 1;
Params.Ra = [];


% Run through variable options

CF_mat = zeros(size(R,2), size(T2a,2), size(T1D,2), size(T2b,2), size(M0b,2), size(Raobs,2), size(b1_field,2) );
GRE_sig = zeros(size(b1_field));
flip_rad = Params.flipAngle*pi/180 ;


tic  % Took 17,000 sec ~ 5 hours
for a = 1:size(R,2)
    Params.R = R(a);
    
    for b = 1:size(T2a,2)
        Params.T2a = T2a(b); 
        
        for c = 1:size(T1D,2)
            Params.T1D = T1D(c); 
            
            for d = 1:size(T2b,2)
                Params.T2b = T2b(d);  
                
                for e = 1:size(M0b,2)
                    Params.M0b = M0b(e);   
                    
                    for f = 1:size(Raobs,2)
                        Params.Raobs = Raobs(f); 


                        % Calculate MT-w signals
                        for i = 1:size(b1_field,2)
                            Params.b1 = b1_field(i)*B1;    
                            
                            GRE_sig(i) = MAMT_model_2007_5(Params);
                        end

                        % Calculate MTsat and Correction factor.
                        [R1app_vfa, Aapp_vfa] = MAMT_model_simVFA(Params);
                        MTsat = (Aapp_vfa * flip_rad ./ GRE_sig - 1) .* R1app_vfa .* Params.TR - (flip_rad.^2)/2;
                        CF_mat(a,b,c,d,e,f,:) = (MTsat(b1_field == 1)- MTsat)./MTsat;
    
                    end
                end
            end
        end
    end
end
    
    
toc




% Reformat into 2D matrix. 
idx = 1;
for a = 1:size(R,2)
    Params.R = R(a);
    
    for b = 1:size(T2a,2)
        Params.T2a = T2a(b); 
        
        for c = 1:size(T1D,2)
            Params.T1D = T1D(c); 
            
            for d = 1:size(T2b,2)
                Params.T2b = T2b(d);  
                
                for e = 1:size(M0b,2)
                    Params.M0b = M0b(e);   
                    
                    for f = 1:size(Raobs,2)
                        Params.Raobs = Raobs(f); 


                        % Calculate MT-w signals
                        for i = 1:size(b1_field,2)
                            Params.b1 = b1_field(i)*B1;    
                            
                            PCA_mat(idx,:) = [Params.R, Params.T2a, Params.T1D,Params.T2b,Params.M0b,Params.Raobs,Params.b1,CF_mat(a,b,c,d,e,f,i)];
                            idx = idx +1;
                        end
    
                    end
                end
            end
        end
    end
end



%% Now run a PCA analysis to see how many variables are needed.
% https://www.mathworks.com/help/stats/pca.html

[PCAres.coeff,PCAres.score,PCAres.latent,PCAres.tsquared,PCAres.explained,PCAres.mu] = pca(PCA_mat);

save(outputPCAmatrix,'PCA_mat')





