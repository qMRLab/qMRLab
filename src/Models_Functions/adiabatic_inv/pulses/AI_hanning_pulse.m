function [rf_pulse, omega1, A_t, Params] = AI_hanning_pulse( Trf, Params)

%   hanning_pulse Adiabatic Inversion Hanning RF pulse function.
%   pulse = hanning_pulse(Trf, PulseOpt)
%
%   B1(t) = A(t) * exp( -1i *integral(omega1(t')) dt' )
%   where A(t) is the envelope, omega1 is the frequency sweep
%
%   Phase modulation is found from taking the integral of omega1(t)
%   Frequency modulation is time derivative of phi(t)
%
%   For the case of a Hanning pulse:
%   A(t) = A_0 * ((1 + cos(beta*pi*t))/2)
%   lambda = A0^2/(beta*Q)
%   omega1(t) = -lambda ((beta*t)+((4/3)*pi)*sin(beta*pi*t)*(1 +1/4*cos(beta*pi*t)))
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
%                  --> Trf = 10ms
%
%              Kupce, E., & Freeman, R. (1996). Optimized adiabatic pulses 
%              for wideband spin inversion. Journal of Magnetic Resonance, 
%              118(2), 299-303. https://doi.org/https://doi.org/10.1006/jmra.1996.0042 
%                  --> lambda equation, Eq. 10 (added to omega1 for scaling)
%                  --> Added beta for everywhere theres tau to follow
%                  trends in Table 1
%
% To be used with qMRlab
% Written by Amie Demmans & Christopher Rowley 2024


% Function to fill default values;
    if ~isfield(Params, 'PulseOpt')
        Params.PulseOpt = struct();
    end
    
Params.PulseOpt = AI_defaultHanningParams(Params.PulseOpt);
Trf = Trf/1000;
nSamples = Params.PulseOpt.nSamples;  
t = linspace(0, Trf, nSamples);
tau = t-Trf/2;

% Amplitude
A_t = Params.PulseOpt.A0*((1+cos(pi.*tau.*Params.PulseOpt.beta))./2);
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
omegaterm1 = Params.PulseOpt.beta.*tau;
omegaterm2 = (4/(3*pi)*sin(pi.*tau.*Params.PulseOpt.beta));
omegaterm3 = 1+1/4*cos(pi.*tau.*Params.PulseOpt.beta);
omega1 = -lambda.*(omegaterm1+(omegaterm2.*omegaterm3));


% Phase modulation function phi(t):
phiterm1 = (Params.PulseOpt.beta*lambda.*tau.^2)./2;
phiterm2num = lambda*(cos(pi.*tau.*Params.PulseOpt.beta)+4).^2;
phiterm2denom = 6*Params.PulseOpt.beta*pi^2;
phi = phiterm1 - (phiterm2num/phiterm2denom);

% Put together complex RF pulse waveform:
rf_pulse = A_t .* exp(1i .* phi);







