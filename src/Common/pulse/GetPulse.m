function Pulse = GetPulse(alpha, delta, Trf, shape, PulseOpt)
%GETPULSE Generate an RF pulse structure.
%   Pulse = GetPulse(alpha, delta, Trf, shape, PulseOpt)
%
%   --args--
%   alpha: Flip angle (in degrees).
%   delta: Off-resonance frequency (in Hz);
%   Trf: RF pulse duration (in seconds)
%   shape: String. Represents the shape of the RF envelope, and each have
%          their own unique functions handles associated to them.
%
%           -values-
%           'hard'
%           'sinc'
%           'sinchann'
%           'gaussian'
%           'gausshann'
%           'sincgauss'
%
%   --optional args--
%   PulseOpt: Struct. Contains optional parameters for pulse shapes. See
%             pulse shape objective function files for more information.
%
%   See also VIEWPULSE.
%

gamma = 2*pi*42576;

if (nargin < 5)
    PulseOpt = struct;
end

switch shape
    case 'hard';      pulse_fcn = @hard_pulse;  
    case 'sinc';      pulse_fcn = @sinc_pulse;        
    case 'sinchann';  pulse_fcn = @sinchann_pulse;        
    case 'sincgauss'; pulse_fcn = @sincgauss_pulse;        
    case 'gaussian';  pulse_fcn = @gaussian_pulse;        
    case 'gausshann'; pulse_fcn = @gausshann_pulse;    
    case 'fermi';     pulse_fcn = @fermi_pulse;  
end

b1     =  @(t) pulse_fcn(t,Trf,PulseOpt);
if moxunit_util_platform_is_octave
    amp    =  2*pi*alpha / ( 360 * gamma * quad(@(t) (b1(t)), 0, Trf) );
else
    amp    =  2*pi*alpha / ( 360 * gamma * integral(@(t) (b1(t)), 0, Trf) );
end
% amp    =  2*pi*alpha / ( 360 * gamma * integral(@(t) abs(b1(t)), 0, Trf,'ArrayValued',true) );
omega  =  @(t) (gamma*amp*pulse_fcn(t,Trf,PulseOpt));
omega2 =  @(t) (gamma*amp*pulse_fcn(t,Trf,PulseOpt)).^2;

Pulse.pulse_fcn = pulse_fcn;  % Fcn handle to pulse shape function
Pulse.b1     =   b1;          % Fcn handle to pulse envelope amplitude
Pulse.amp    =   amp;         % Pulse max amplitude
Pulse.omega  =   omega;       % Fcn handle to pulse omega1
Pulse.omega2 =   omega2;      % Fcn handle to pulse omega1^2 (power)
Pulse.alpha  =   alpha;       % Flip angle
Pulse.delta  =   delta;       % Pulse offset
Pulse.Trf    =   Trf;         % Pulse duration
Pulse.shape  =   shape;       % Pulse shape string
Pulse.opt    =   PulseOpt;    % Additional options (e.g. TBW for sinc time-bandwidth window, bw for gaussian bandwidth)


end
