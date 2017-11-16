function varargout = qMRinfo(varargin)
% Display Model headers (MR protocol, model detail, fitting parameters, options)
% Example:
%   qMRinfo('MWF'); % display help for Myelin Water Fraction
if ~moxunit_util_platform_is_octave
    if nargin==0, varargin{1}='qMRinfo'; end
    [varargout{1:nargout}] = help(varargin{:});
else
    varargout{1} = 'Sorry, not implemented for Octave yet. Please contribute on github.com/neuropoly/qMRLab';
	disp(varargout{1})
end