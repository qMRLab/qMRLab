% Display Model headers (MR protocol, model detail, fitting parameters, options)
% Example:
%   qMRinfo('mwf'); % display help for Myelin Water Fraction
%
% This function is to provide Octave compatibility for help text.
% Octave accepts a different convention for help documentation. 
% Until we find a through solution for Octave help, we will skip this for
% Octave. 

% This is the reason why this function will be used instead of 'help' 

function varargout = qMRinfo(varargin)
if nargin==0, varargin{1}='Display Model headers (MR protocol, model detail, fitting parameters, options)'; end
if moxunit_util_platform_is_octave || isdeployed
    hh = load('iqmr_gethelp.mat');
    if ischar(varargin{1})
        varargout{1} = hh.(varargin{1});
    else
        varargout{1} = hh.(class(varargin{1}));
    end
else
    [varargout{1:nargout}] = help(varargin{:});
end