function [rf_pulse, omega1, A_t, Params] = AI_gauss_pulse( Trf, Params)

%   gauss_pulse Adiabatic Inversion Gaussian RF pulse function.
%   pulse = gauss_pulse(Trf, PulseOpt)
%
%   B1(t) = A(t) * exp( -1i *integral(omega1(t')) dt' )
%   where A(t) is the envelope, omega1 is the frequency sweep
%
%   Phase modulation is found from taking the integral of omega1(t)
%   Frequency modulation is time derivative of phi(t)
%
%   For the case of a Gauus pulse:
%   A(t) = A_0 * exp((-beta^2 * t^2)/2)
%   lambda = A0^2/(beta*Q)
%   omega1(t) = -lamdba*(erf(beta*t)/erf(beta))
%
%   A0 is the peak amplitude in microTesla
%   beta is a frequency modulation parameter in rad/s
%
%   The pulse is defined to be 0 outside the pulse window (before 
%   t = 0 or after t=Trf). (HSn, n = 1-8+) 
%
%   --args--
%   t: Function handle variable, represents the time.
%   Trf: Duration of the RF pulse in seconds.
%
%   --optional args--
%   PulseOpt: Struct. Contains optional parameters for pulse shapes.
%   PulseOpt.Beta: frequency modulation parameter
% 
%   Reference: Matt A. Bernstein, Kevin F. Kink and Xiaohong Joe Zhou.
%              Handbook of MRI Pulse Sequences, pp. 110, Eq. 4.10, (2004)
%
%              Tannús, A., & Garwood, M. (1997). Adiabatic pulses. NMR in 
%              Biomedicine: An International Journal Devoted to the 
%              Development and Application of Magnetic Resonance In Vivo, 
%              10(8), 423-434. https://doi.org/10.1002/(sici)1099-1492(199712)10:8 
%                  --> Table 1 contains all modulation functions 
%                  --> A(t), omega1
%                  --> Fig 5, Gaussian OIA pulse image 
%                  --> Trf = 10 ms 
%
%              Kupce, E., & Freeman, R. (1996). Optimized adiabatic pulses 
%              for wideband spin inversion. Journal of Magnetic Resonance, 
%              118(2), 299-303. https://doi.org/https://doi.org/10.1006/jmra.1996.0042 
%                  --> lambda equation, Eq. 10 (added to omega1 for scaling)
%
%              Tannús, A., & Garwood, M. (1996). Improved performance of 
%              frequency-swept pulses using offset-independent adiabaticity. 
%              Journal of Magnetic Resonance, 120(1), 133-137. 
%              https://doi.org/https://doi.org/10.1006/jmra.1996.0110 
%                   --> Fig 1a and 1b. Show how width of amplitude and
%                   frequency vary with each pulse
%
% To be used with qMRlab
% Written by Amie Demmans & Christopher Rowley 2024


% Function to fill default values;
    if ~isfield(Params, 'PulseOpt')
        Params.PulseOpt = struct();
    end
    
Params.PulseOpt = AI_defaultGaussParams(Params.PulseOpt);
Trf = Trf/1000;
nSamples = Params.PulseOpt.nSamples;  
t = linspace(0, Trf, nSamples);
tau = t-Trf/2;

% Amplitude 
A_t = Params.PulseOpt.A0 .* exp(-1*(Params.PulseOpt.beta.^2 .* tau.^2)./2);
A_t((t < 0 | t>Trf)) = 0;
% disp( ['Average B1 of the pulse is:', num2str(mean(A_t))]) 

% Scaling Factor (lambda) 
% --> Setting Q = 0 allows for viewing of RF pulse 
if Params.PulseOpt.Q == 0 
    lambda = 0;
else 
    lambda = (Params.PulseOpt.A0)^2 ./ (Params.PulseOpt.beta.*Params.PulseOpt.Q);
end 

% Frequency modulation function 
% Carrier frequency modulation function w(t):  
omega1 = -lambda*erf(Params.PulseOpt.beta.*tau)./erf(Params.PulseOpt.beta);

% Phase modulation function phi(t):
phi1num = lambda.*tau.*erf(Params.PulseOpt.beta.*tau);
phi1denom = erf(Params.PulseOpt.beta);
phi1 = phi1num/phi1denom;
phi2num = lambda*exp(-Params.PulseOpt.beta.^2 .* tau.^2);
phi2denom = sqrt(pi)*Params.PulseOpt.beta*erf(Params.PulseOpt.beta);  
phi2 = phi2num/phi2denom;
phi = phi1+phi2;

% Put together complex RF pulse waveform:
rf_pulse = A_t .* exp(1i .* phi);




