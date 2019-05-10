function obj=MOcovProgressMonitor(verbosity)
% initialize MOcovProgressMonitor
%
% obj=MOcovProgressMonitor(verbosity)
%
% Inputs:
%   verbosity               integer; the higher, the more verbose output is
%                           provided. Default: 1
%
% Notes:
% - the main purpose of this class is providing a method "notify" which,
%   when called as notify(obj, s1, s2, ..., sN) prints the string sK to
%   standard output, where K is the verbosity level (if the verbosity level
%   is higher than N, K=N)

    if nargin<1
        verbosity=1;
    end

    props=struct();
    props.verbosity=verbosity;
    props.char_counter=0;
    props.max_chars=60;
    obj=class(props,'MOcovProgressMonitor');

