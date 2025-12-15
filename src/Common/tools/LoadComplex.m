function [data, hdr] = LoadComplex(varargin)
% Read a complex-valued image provided in two separate files.
%
% LOADCOMPLEX('path/to/file_PHASE.ext','path/to/file_MAGNITUDE.ext')
%   Guess the content of each file based on the paths, looking for
%   (case insensitive) occurrences of the "component" labels, i.e.:
%   'real','imaginary','phase', and 'magnitude'.
%
% LOADCOMPLEX('/path/to/files_*.ext')
%   Expand the pattern, then do the same as above.
%
% LOADCOMPLEX('real','foo.ext','imaginary','bar.ext')
%   Specify two "components" explicitly.
%
% LOADCOMPLEX(..., @LoadFunction)
%   Overload the default @BrowserSet.LoadImage to load individual images.
%   The function must return a DATA array and a HDR structure.
%
% See also: BrowserSet.LoadImage, BrowserSet.LoadAny, LoadImage

    labels = {'real','imaginary','phase','magnitude'}';

    if ~isempty(varargin) && isa(varargin{end}, 'function_handle')
        LoadFunction = varargin{end};
        varargin(end) = [];
    else
        LoadFunction = @BrowserSet.LoadImage;
    end

    try
        switch numel(varargin)
        case 1
            paths = arrayfun(@(x) fullfile(x.folder, x.name), dir(varargin{1}), 'unif', 0);
        case 2
            assert(all(cellfun(@isfile, varargin)), 'Expecting 2 file paths')
            paths = varargin;
        case 4
            varargin(1:2:end) = lower(varargin(1:2:end));
            assert(isempty(setdiff(varargin(1:2:end), labels)), ...
                'Expecting arguments 1,3 to be one of: %s', strjoin(labels, ', '))
            assert(all(cellfun(@isfile, varargin(2:2:end))), ...
                'Expecting arguments 2,4 to be file paths')
            paths = struct(varargin{:});
        otherwise
            error('Unrecognized arguments')
        end

        if iscell(paths)
            assert(numel(paths) >= 2, 'Expecting two or more paths')
            assert(all(cellfun(@isfile, paths)), 'Invalid file path(s)')
        end
    catch err
        error('qMRLab:LoadComplex:args', err.message)
    end

    if iscell(paths)
        paths = MatchPathsToLabels(paths, labels);
    end

    % read individual images
    [data, hdr] = structfun(LoadFunction, paths, 'unif', 0);

    if isfield(paths ,'phase')
        data.phase = CheckPhaseBounds(data.phase);
    end

    % Complex integer arithmetic is not supported
    for f = fieldnames(paths)'
        if isinteger(data.(f{1}))
            data.(f{1}) = single(data.(f{1}));
        end
    end

    if isfield(paths, 'magnitude')
        if isfield(paths ,'phase')
        % magnitude + phase
            data = data.magnitude.*exp(1i*data.phase);
        else
        % magnitude + imaginary / real is ambiguous (sign unknown)
            warning('qMRLab:LoadComplex:ambiguous', ...
                ['Cannot get complex phase from %s, returning ', ...
                '(real) magnitude'], strjoin(fieldnames(data),'+'))
            data = data.magnitude;
        end
    elseif isfield(paths, 'real')
        if isfield(paths ,'phase')
        % real + phase
            data = complex(data.real, data.real.*tan(data.phase));
        elseif isfield(paths, 'imaginary')
        % real + imaginary
            data = complex(data.real, data.imaginary);
        end
    elseif isfield(paths, 'imaginary')
        % imaginary + phase
        data = data.imaginary.*complex(1./tan(data.phase), 1);
    else
        error('Unexpected error')
    end

    hdr = MergeHeader(hdr);

    % Fix NIFTI datatype
    if all(isfield(hdr,{'datatype','bitpix'}))
        switch class(data)
        case 'double'
            hdr.datatype = 1792; % complex (128 bits/voxel)
            hdr.bitpix = 128;
        case 'single'
            hdr.datatype = 32; % complex (64 bits/voxel)
            hdr.bitpix = 64;
        end
    end
end

function s = MatchPathsToLabels(paths, labels)

    found = false(numel(paths), numel(labels));
    for j = 1:numel(labels)
        found(:,j) = cellfun(@(p) contains(p,labels{j},'IgnoreCase',1), paths);
    end

    [r, c] = ind2sub(size(found), find(found));
    matched_labels = labels(c);
    matched_paths = paths(r);

    if numel(r) ~= 2 || numel(unique(r)) ~= 2 || numel(unique(c)) ~= 2
        if numel(r) == 0
            msg = 'no paths matched labels';
        else
            msg = strjoin(cellfun(@(x,y) sprintf('%s: %s',x,y), ...
                matched_labels, matched_paths, 'unif',false), '\n');
        end
        error('qMRLab:LoadComplex:match', 'Failed to match two complex components: \n%s', msg);
    end
    s = cell2struct(matched_paths(:), matched_labels);
end

function phaseData = CheckPhaseBounds(phaseData)
    [lo, hi] = bounds(phaseData(:));
    if lo < -pi && hi > pi
        scale = ceil(max(abs([lo, hi])));
        phaseData = phaseData * pi / scale;
        warning('qMRLab:LoadComplex:phasebounds', ...
            ['Phase data range [%0.1f, %0.1f] outside expected ', ...
            '+/-pi, normalizing by pi / %0.1f'], lo, hi, scale)
    end
end

function H = MergeHeader(hdr)
% Simple "outer join" between hdr.A and hdr.B
% Common fields with different values will be parsed to structures
%   H.X = struct(A, hdr.a, B, hdr.b)

    labels = fieldnames(hdr);
    h = struct2cell(hdr);
    assert(numel(labels)==2)

    fld1 = fieldnames(h{1});
    fld2 = fieldnames(h{2});

    H = h{1};
    for f = setdiff(fld2, fld1)'
        H.(f{1}) = h{2}.(f{1});
    end
    for f = intersect(fld2, fld1)'
        v1 = h{1}.(f{1});
        v2 = h{2}.(f{1});
        if ~isequal(v1, v2)
            H.(f{1}) = struct(labels{1}, v1, labels{2}, v2);
        end
    end
end