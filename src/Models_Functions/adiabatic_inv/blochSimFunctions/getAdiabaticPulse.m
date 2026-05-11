function [rf_pulse, omega1, A_t, Params] = getAdiabaticPulse( Trf, shape, Params)

% This need to take in parameter related to the adiabatic pulse, and return
% the B1. 
% Returns the complex adiabatic pulse, and the parameters.
% dispFig is a flag to return the BlochSimulation results. 

%GetAdiabaticPulse Generate an Adiabatic pulse structure.
%   Pulse = getAdiabaticPulse(Trf, shape, PulseOpt)
%
%   A note on adiabatic pulses:
%   B1(t) = A(t) * exp( -1i *integral(omega1(t')) dt' )
%   where A(t) is the envelope, omega1 is the frequency sweep
%
%   --args--
%   Trf: adiabatic pulse duration (in ms)
%   shape: String. Represents the shape of the adiabatic envelope, and 
%   each have their own unique functions handles associated to them.
%
%           -values-
%           'Hs1'
%           'Lorentz'
%           'Gauss'
%           'Hanning'
%           'Hsn'
%           'Sin40'
%
%   --optional args--
%   Params: Struct. Contains optional parameters for pulse shapes. Need
%   Params.x as in adiabatic_inv (qMRLab) and adiabaticExample. 
%
%   All references listed below code 
%   
%   Written by Amie Demmans & Christopher Rowley 2024
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin < 3) 
    Params.PulseOpt = struct;
end

switch shape

    case 'Hs1'        
        [rf_pulse, omega1, A_t, Params] = AI_hs1_pulse(Trf, Params);
    case 'Lorentz'
        [rf_pulse, omega1, A_t, Params] = AI_lorentz_pulse(Trf, Params);
    case 'Gaussian'
        [rf_pulse, omega1, A_t, Params] = AI_gauss_pulse(Trf, Params);
    case 'Hanning'
        [rf_pulse, omega1, A_t, Params] = AI_hanning_pulse(Trf, Params);
    case 'Hsn'
        [rf_pulse, omega1, A_t, Params] = AI_hsn_pulse(Trf, Params);
    case 'Sin40'
        [rf_pulse, omega1, A_t, Params] = AI_sin40_pulse(Trf, Params);

end


end

%% For each reference listed, the following important information covered is listed underneath  

%  De Graaf, R. A. (2016). Adiabatic Excitation Pulses for MRS. In Handbook 
%   of Magnetic Resonance Spectroscopy In Vivo: MRS Theory, Practice and 
%   Applications (pp. 1003-1014). John Wiley & Sons, Incorporated. 
%   https://doi.org/10.1002/9780470034590.emrstm1443 
%   --> Adiabatic RF pulses 
%   --> Modulation functions 
%   --> Adiabatic Condition 
%
%  De Graaf, R. A., & Nicolay, K. (1997). Adiabatic rf pulses: Applications 
%   to in vivo NMR. Concepts in Magnetic Resonance: An Educational Journal, 
%   9(4), 247-268. https://doi.org/10.1002/(sici)1099-0534(1997)9:4<247::Aid-cmr4>3.0.Co;2-z 
%   --> Adiabatic half passage and full passage 
%   --> Adiabatic inversion pulses 
%
%  Garwood, M., & DelaBarre, L. (2001). The return of the frequency sweep: 
%   designing adiabatic pulses for contemporary NMR. Journal of Magnetic 
%   Resonance, 153(2), 155-177. https://doi.org/10.1006/jmre.2001.2340
%   --> Hyperbolic secant pulse (Hs1 and Hs8) 
%
%  Kupce, E., & Freeman, R. (1995). Stretched adiabatic pulses for wideband 
%   spin inversion. Journal of Magnetic Resonance, 117(2), 246-256. 
%   https://doi.org/https://doi.org/10.1006/jmra.1995.0750 
%   --> Adiabatic Condition 
%   --> Adiabaticity Factor, Q
%   --> Scaling factor, lambda 
%
%  Kupce, E., & Freeman, R. (1996). Optimized adiabatic pulses for wideband 
%   spin inversion. Journal of Magnetic Resonance, 118(2), 299-303. 
%   https://doi.org/https://doi.org/10.1006/jmra.1996.0042 
%   --> Adiabaticity factor, Q
%   --> Scaling factor, lambda 
%
%  Matt A. Bernstein, Kevin F. King, & Zhou, X. J. (2004a). Adiabatic 
%   Radiofrequency Pulses. In Matt A. Bernstein, Kevin F. King, & X. J. Zhou 
%   (Eds.), Handbook of MRI Pulse Sequences (pp. 117-212). Academic Press.
%   https://doi.org/https://doi.org/10.1016/B978-012092861-3/50010-8 
%   --> Adiabatic Inversion Pulses 
%
%  Matt A. Bernstein, Kevin F. King, & Zhou, X. J. (2004b). Inversion Pulses. 
%   In Matt A. Bernstein, Kevin F. King, & X. J. Zhou (Eds.), Handbook of 
%   Mri Pulse Sequences (pp. 77-84). Academic Press. 
%   --> Inversion Pulses 
%
%  Murase, K., & Tanki, N. (2011). Numerical solutions to the time-dependent 
%   Bloch equations revisited. Magnetic Resonance Imaging, 29(1), 126-131. 
%   https://doi.org/10.1016/j.mri.2010.07.003 
%   --> Bloch equations for 1 pool and 2 pool 
%
%  Tannús, A., & Garwood, M. (1996). Improved performance of frequency-swept 
%   pulses using offset-independent adiabaticity. Journal of Magnetic Resonance, 1
%   20(1), 133-137. https://doi.org/https://doi.org/10.1006/jmra.1996.0110 
%   --> List of modulation functions 
%   --> Expected plots for AM and FM functions
%
%  Tannús, A., & Garwood, M. (1997). Adiabatic pulses. NMR in Biomedicine: 
%   An International Journal Devoted to the Development and Application of 
%   Magnetic Resonance In Vivo, 10(8), 423-434. 
%   https://doi.org/10.1002/(sici)1099-1492(199712)10:8<423::Aid-nbm488>3.0.Co;2-x 
%   --> Adiabatic RF pulses 
%   --> List of Modulation Functions 
%
%  Tesiram, Y. A. (2010). Implementation equations for HSn RF pulses. Journal 
%   of Magnetic Resonance, 204(2), 333-339. https://doi.org/10.1016/j.jmr.2010.02.022 
%   --> Hyperbolic secant pulse 
%
%  Ward, K. M., Aletras, A. H., & Balaban, R. S. (2000). A new class of 
%   contrast agents for MRI based on proton chemical exchange dependent 
%   saturation transfer (CEST). Journal of Magnetic Resonance, 143(1), 79-87. 
%   https://doi.org/10.1006/jmre.1999.1956 
%   --> Bloch equations 2 pool 
















