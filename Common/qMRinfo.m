function qMRinfo(varargin)
if ~moxunit_util_platform_is_octave
    help(varargin{:})
else
    disp('Sorry, not implemented for Octave yet. Please contribute on github.com/neuropoly/qMRLab')
end