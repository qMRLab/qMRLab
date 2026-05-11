function [rf_pulse, omega1, A_t, Params] = AI_hsn_pulse(Trf, Params)

%   hsn_pulse Adiabatic Inversion hyperbolic secant RF pulse function.
%   pulse = hsn_pulse(Trf, PulseOpt)
%
%   B1(t) = A(t) * exp( -1i *integral(omega1(t')) dt' )
%   where A(t) is the envelope, omega1 is the frequency sweep
%
%   Phase modulation is found from taking the integral of omega1(t)
%   Frequency modulation is time derivative of phi(t)
%
%   For the case of a hyperbolic secant (n = 2-8) pulse:
%   A(t) = A0 * sech((beta*t)^n)
%   lambda = (A_0^2/(beta*Q))^2
%   omega1(t) = integral(sech^2(beta*t^n)
%
%   A0 is the peak amplitude in microTesla
%   Beta is a frequency modulation parameter in rad/s
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
%                   --> A(t), omega1 
%
%              Kupce, E., & Freeman, R. (1996). Optimized adiabatic pulses 
%              for wideband spin inversion. Journal of Magnetic Resonance, 
%              118(2), 299-303. https://doi.org/https://doi.org/10.1006/jmra.1996.0042 
%                   --> lambda equation added to omega 1 for scaling, Eq.10
%
%              Tesiram, Y. A. (2010). Implementation equations for HSn RF 
%              pulses. Journal of Magnetic Resonance, 204(2), 333-339. 
%              https://doi.org/10.1016/j.jmr.2010.02.022 
%                   --> Placing beta ^n 
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
% Written by Amie Demmans & Christopher Rowley 2024


% Function to fill default values;
    if ~isfield(Params, 'PulseOpt')
        Params.PulseOpt = struct();
    end
    
Params.PulseOpt = AI_defaultHsnParams(Params.PulseOpt);
Trf = Trf/1000;
nSamples = Params.PulseOpt.nSamples;  
t = linspace(0, Trf, nSamples);
tau = t-Trf/2;

% Amplitude
A_t =  Params.PulseOpt.A0* sech((Params.PulseOpt.beta .*tau).^Params.PulseOpt.n);
A_t((t < 0 | t>Trf)) = 0;
% disp( ['Average B1 of the pulse is:', num2str(mean(A_t))]) 

% Scaling Factor (lambda) 
% --> Setting Q = 0 allows for viewing of RF pulse 
if Params.PulseOpt.Q == 0 
    lambda = 0;
else 
    lambda = ((Params.PulseOpt.A0)^2 ./ (Params.PulseOpt.beta.*Params.PulseOpt.Q))^2;
end

% Frequency modulation function 
% Carrier frequency modulation function w(t):
omegaterm1 = sech((Params.PulseOpt.beta .* tau).^Params.PulseOpt.n).^2;
omegaterm2 = -lambda*cumtrapz(tau,omegaterm1);
omegaterm3 = (omegaterm2(1)-omegaterm2(512))/2;
omega1 = omegaterm2+omegaterm3; 

% Phase modulation function phi(t):
phi = cumtrapz(tau, omega1);

% Put together complex RF pulse waveform:
rf_pulse = A_t .* exp(1i .* phi);





