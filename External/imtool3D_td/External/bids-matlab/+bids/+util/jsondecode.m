function value = jsondecode(file, varargin)
% Decode JSON-formatted file
% FORMAT value = bids.util.jsondecode(file, opts)
% file     - name of a JSON file or JSON string
% opts     - structure of optional parameters (only with JSONio):
%              replacementStyle: string to control how non-alphanumeric
%              characters are replaced {'underscore','hex','delete','nop'}
%              [Default: 'underscore']
%
% json     - JSON structure

% Copyright (C) 2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2018--, BIDS-MATLAB developers


if exist('jsondecode','builtin') == 5               % MATLAB >= R2016b
    value = builtin('jsondecode', fileread(file));
elseif exist('spm_jsonread','file') == 3            % SPM12
    value = spm_jsonread(file, varargin{:});
elseif exist('jsonread','file') == 3                % JSONio
    value = jsonread(file, varargin{:});
else
    error('JSON library required: install JSONio from https://github.com/gllmflndn/JSONio');
end
