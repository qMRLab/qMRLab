function [satPulse, sinc_ExcPulse] = MAMT_preparePulses(Params)
%% This function generates the time varying pulses given sequence parameters
% other pulse shapes can easily be added below 

%% Prep the Saturation Pulse
tSat = 0 : Params.stepSize : Params.pulseDur;
len = size(tSat,2);
if strcmp(Params.SatPulseShape, 'hanning')
    
    sat_wind = 0.5*(1-cos(2*pi*tSat/(Params.pulseDur))); % there is a function for this, but we will explicitly write it

    % want to get the approximate integral to see the height parameter/ check RMS
    sat_rms =  trapz(tSat,sat_wind.^2);
    square_rms = Params.pulseDur*Params.b1.^2;
    sat_amp = sqrt(square_rms /sat_rms);
    satPulse = sat_wind.*sat_amp; % B1 in uT, regenerate hann_wind with the right height
    
elseif  strcmp(Params.SatPulseShape, 'gaussian')
    
    sat_wind = exp(-1/2*(tSat - Params.pulseDur/2 ).^2 ./ (Params.pulseDur/4)^2 );

    % want to get the approximate integral to see the height parameter/ check RMS
    sat_rms =  trapz(tSat,sat_wind.^2);
    square_rms = Params.pulseDur*Params.b1.^2;
    sat_amp = sqrt(square_rms /sat_rms);
    satPulse = sat_wind.*sat_amp; % B1 in uT, regenerate hann_wind with the right height
    
elseif  strcmp(Params.SatPulseShape, 'fermi')
    
    % Code kindly donated from Agâh Karakuzu and http://qmrlab.org/
    %   Reference: Matt A. Bernstein, Kevin F. Kink and Xiaohong Joe Zhou.
    %   Handbook of MRI Pulse Sequences, pp. 111, Eq. 4.14, (2004)
    Trf = Params.pulseDur;
    slope = Trf/33.81;          % Assuming t0 = 10a  

    t0 = (Trf - 13.81*slope)/2;  
    sat_wind = 1 ./ ( 1 + exp( (abs(tSat-Trf/2) - t0) ./ slope ) );
 
    % want to get the approximate integral to see the height parameter/ check RMS
    sat_rms =  trapz(tSat,sat_wind.^2);
    square_rms = Params.pulseDur*Params.b1.^2;
    sat_amp = sqrt(square_rms /sat_rms);
    satPulse = (sat_wind).*sat_amp; % B1 in uT, regenerate hann_wind with the right height

elseif  strcmp(Params.SatPulseShape, 'square')

    satPulse = ones(1,len)*Params.b1; % B1 in uT, regenerate hann_wind with the right height
else
    error('Error: Define Saturation Pulse Shape')
    
end

% % check
% figure; plot(tSat, satPulse)
% yline(Params.b1)
% 
% square_rms = Params.pulseDur*Params.b1.^2

%% Prep the Water Excitation Pulse
tExc = 0 : Params.stepSize : Params.WExcDur;
x = linspace(-pi,pi, size(tExc,2));
sinc_wind = sinc(x);

% want to get the approximate integral to see the height parameter/ check RMS
w_b1 = Params.flipAngle/ (360 *42.57748 * Params.WExcDur);

sinc_rms =  trapz(tExc,sinc_wind.^2);
square_rms = Params.WExcDur * w_b1.^2;

sinc_amp = sqrt(square_rms /sinc_rms);
sinc_ExcPulse = sinc_wind.*sinc_amp; % B1 in uT, regenerate hann_wind with the right height

% figure; plot(tExc, sinc_ExcPulse)

