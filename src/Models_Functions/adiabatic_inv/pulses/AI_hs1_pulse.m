function [rf_pulse, omega1, A_t, Params] = AI_hs1_pulse(Trf, Params)

%   hyperbolicSecant_pulse Adiabatic Inversion hyperbolic secant RF pulse function.
%   pulse = hyperbolicSecant_pulse(t, Trf, PulseOpt)
%
%   B1(t) = A(t) * exp( -1i *integral(omega1(t')) dt' )
%   where A(t) is the envelope, omega1 is the frequency sweep
%
%   Phase modulation is found from taking the integral of omega1(t)
%   Frequency modulation is time derivative of phi(t)
%
%   For the case of a hyperbolic secant pulse:
%   A(t) = A0 * sech(Beta*t)
%   omega1(t) = -mu*Beta*tanh(Beta*t)
%
%   A0 is the peak amplitude in microTesla
%   Beta is a frequency modulation parameter in rad/s
%   mu is a phase modulation parameter (dimensionless)
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
%   PulseOpt.n: time modulation - Typical 4 for non-selective, 1 for slab
%   Reference: Matt A. Bernstein, Kevin F. Kink and Xiaohong Joe Zhou.
%              Handbook of MRI Pulse Sequences, pp. 110, Eq. 4.10, (2004)
%
%              Tannús, A., & Garwood, M. (1997). Adiabatic pulses. NMR in 
%              Biomedicine: An International Journal Devoted to the 
%              Development and Application of Magnetic Resonance In Vivo, 
%              10(8), 423-434. https://doi.org/10.1002/(sici)1099-1492(199712)10:8 
%                   --> Table 1 contains all modulation functions 
%
%              Garwood, M., & DelaBarre, L. (2001). The return of the frequency
%              sweep: designing adiabatic pulses for contemporary NMR. Journal
%              of Magnetic Resonance, 153(2), 155-177. 
%              https://doi.org/10.1006/jmre.2001.2340 
%                   --> A(t), omega1, mu(phase modulation parameter)
%
%              Tannús, A., & Garwood, M. (1996). Improved performance of 
%              frequency-swept pulses using offset-independent adiabaticity. 
%              Journal of Magnetic Resonance, 120(1), 133-137. 
%              https://doi.org/https://doi.org/10.1006/jmra.1996.0110 
%                   --> Fig 1a and 1b. Show how width of amplitude and
%                   frequency vary with each pulse
%
%
% To be used with qMRlab
% Written by Christopher Rowley 2023 & Amie Demmans 2024


% Function to fill default values;
    if ~isfield(Params, 'PulseOpt')
        Params.PulseOpt = struct();
    end
    
Params.PulseOpt = AI_defaultHs1Params(Params.PulseOpt);
Trf = Trf/1000;
nSamples = Params.PulseOpt.nSamples;  
t = linspace(0, Trf, nSamples);
tau = t-Trf/2;

% Amplitude
A_t =  Params.PulseOpt.A0* sech(Params.PulseOpt.beta* ( (tau)).^Params.PulseOpt.n);
A_t((t < 0 | t>Trf)) = 0;
% disp( ['Average B1 of the pulse is:', num2str(mean(A_t))]) 

% Frequency modulation function 
% Carrier frequency modulation function w(t):
% NOTE: Q in Hs1 is NOT the same as in the other pulses, Q = mu
omega1 = -Params.PulseOpt.Q.*Params.PulseOpt.beta .* ...
            tanh(Params.PulseOpt.beta .* (tau))./(2*pi); % 2pi to convert from rad/s to Hz

% Phase modulation function phi(t):
phi = Params.PulseOpt.Q .* log(sech(Params.PulseOpt.beta .* (tau)) );

% Put together complex RF pulse waveform:
rf_pulse = A_t .* exp(1i .* phi);










































