function varargout = qMRinfo(varargin)
if ~moxunit_util_platform_is_octave
    [varargout{1:nargout}] = help(varargin{:});
else
    varargout{1} = 'Sorry, not implemented for Octave yet. Please contribute on github.com/neuropoly/qMRLab';
	disp(varargout{1})
end