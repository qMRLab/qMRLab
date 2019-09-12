function meta = get_metadata(filename, pattern)
% Read a BIDS's file metadata according to the inheritance principle
% FORMAT meta = get_metadata(filename, pattern)
% filename    - name of file following BIDS standard
% pattern     - regular expression matching metadata file
% meta        - metadata structure
%__________________________________________________________________________

% Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2018--, BIDS-MATLAB developers


if nargin == 1, pattern = '^.*_%s\\.json$'; end
pth = fileparts(filename);
p = parse_filename(filename);

meta = struct();

N = 3;
if isfield(p,'ses') && ~isempty(p.ses)
    N = N + 1; % there is a session level in the hierarchy
end
    
for n=1:N
    metafile = file_utils('FPList',pth, sprintf(pattern,p.type));
    if isempty(metafile), metafile = {}; else metafile = cellstr(metafile); end
    for i=1:numel(metafile)
        p2 = parse_filename(metafile{i});
        fn = setdiff(fieldnames(p2),{'filename','ext','type'});
        ismeta = true;
        for j=1:numel(fn)
            if ~isfield(p,fn{j}) || ~strcmp(p.(fn{j}),p2.(fn{j}))
                ismeta = false;
                break;
            end
        end
        if ismeta
            if strcmp(p2.ext,'.json')
                meta = update_metadata(meta,bids.util.jsondecode(metafile{i}));
            else
                meta.filename = metafile{i};
            end
        end
    end
    pth = fullfile(pth,'..');
end


%==========================================================================
%-Inheritance principle
%==========================================================================
function s1 = update_metadata(s1,s2)
fn = fieldnames(s2);
for i=1:numel(fn)
    if ~isfield(s1,fn{i})
        s1.(fn{i}) = s2.(fn{i});
    end
end
