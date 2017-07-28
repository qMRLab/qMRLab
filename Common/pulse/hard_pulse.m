function pulse = hard_pulse(t,Trf,~)
%HARD_PULSE Hard (square) RF pulse function.
%   pulse = hard_pulse(t,Trf,~)
%
%   The hard/square pulse is defined to be 1 from when the pulse starts 
%   (t=0) until it ends (t=Trf), and is 0 elsewhere. 
%
%   Note that the last argument is ignored, due to how GETPULSE calls its
%   functions using function handles (eg., hard_pulse has no additional
%   pulse options.)
%
%   --args--
%   t: Function handle variable, represents the time.
%   Trf: Width of the hard/square RF pulse.
%

pulse = single(~(t < 0 | t>Trf));

end

%   See also GETPULSE, VIEWPULSE.
