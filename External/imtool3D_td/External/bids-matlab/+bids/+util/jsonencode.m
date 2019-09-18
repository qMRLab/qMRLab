function varargout = jsonencode(varargin)
% Encode data to JSON-formatted file
% FORMAT bids.util.jsonencode(filename,json)
% filename - JSON filename
% json     - JSON structure
%
% FORMAT S = bids.util.jsonencode(json)
% json     - JSON structure
% S        - serialized JSON structure (string)
%
% FORMAT [...] = bids.util.jsonencode(...,opts)
% opts     - structure of optional parameters:
%              Indent: string to use for indentation [Default: '']
%              ReplacementStyle: string to control how non-alphanumeric
%                characters are replaced [Default: 'underscore']
%              ConvertInfAndNaN: encode NaN, Inf and -Inf as "null"
%                [Default: true]

% Copyright (C) 2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2018--, BIDS-MATLAB developers


if ~nargin
    error('Not enough input arguments.');
end

if exist('spm_jsonwrite','file') == 2                    % SPM12
    [varargout{1:nargout}] = spm_jsonwrite(varargin{:});
elseif exist('jsonwrite','file') == 2                    % JSONio
    [varargout{1:nargout}] = jsonwrite(varargin{:});
elseif exist('jsonencode','builtin') == 5                % MATLAB >= R2016b
    file = '';
    if ischar(varargin{1})
        file = varargin{1};
        varargin(1) = [];
    end
    if numel(varargin) > 1
        opts = varargin{2};
        varargin(2) = [];
        fn   = fieldnames(opts);
        for i=1:numel(fn)
            if strcmpi(fn{i},'ConvertInfAndNaN')
                varargin(2:3) = {'ConvertInfAndNaN',opts.(fn{i})};
            end
        end
    end
    txt = builtin('jsonencode', varargin{:});
    if ~isempty(file)
        fid = fopen(file,'wt');
        if fid == -1
            error('Unable to open file "%s" for writing.',file);
        end
        fprintf(fid,'%s',txt);
        fclose(fid);
    end
    varargout = { txt };
else
    error('JSON library required: install JSONio from https://github.com/gllmflndn/JSONio');
end
