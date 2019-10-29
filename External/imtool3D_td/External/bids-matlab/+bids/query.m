function result = query(BIDS,query,varargin)
% Query a directory structure formated according to the BIDS standard
% FORMAT result = bids.query(BIDS,query,...)
% BIDS   - BIDS directory name or BIDS structure (from bids.layout)
% query  - type of query: {'data', 'metadata', 'sessions', 'subjects',
%          'runs', 'tasks', 'runs', 'types', 'modalities'}
% result - outcome of query
%__________________________________________________________________________
%
% BIDS (Brain Imaging Data Structure): https://bids.neuroimaging.io/
%   The brain imaging data structure, a format for organizing and
%   describing outputs of neuroimaging experiments.
%   K. J. Gorgolewski et al, Scientific Data, 2016.
%__________________________________________________________________________

% Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2018--, BIDS-MATLAB developers


if nargin < 2
    error('Not enough input arguments.');
end

BIDS = bids.layout(BIDS);

opts = parse_query(varargin);

switch query
%   case 'subjects'
%       result = regexprep(unique({BIDS.subjects.name}),'^[a-zA-Z0-9]+-','');
    case 'modalities'
        hasmod = arrayfun(@(y) structfun(@(x) isstruct(x) & ~isempty(x),y),...
            BIDS.subjects,'UniformOutput',false);
        hasmod = any([hasmod{:}],2);
        mods   = fieldnames(BIDS.subjects)';
        result = mods(hasmod);
    case {'sessions','subjects', 'tasks', 'runs', 'types', 'data', 'metadata'}
        %-Initialise output variable
        result = {};
        %-Filter according to subjects
        if any(ismember(opts(:,1),'sub'))
            subs = opts{ismember(opts(:,1),'sub'),2};
            opts(ismember(opts(:,1),'sub'),:) = [];
        else
            subs = unique({BIDS.subjects.name});
            subs = regexprep(subs,'^[a-zA-Z0-9]+-','');
        end
        %-Filter according to modality
        if any(ismember(opts(:,1),'modality'))
            mods = opts{ismember(opts(:,1),'modality'),2};
            opts(ismember(opts(:,1),'modality'),:) = [];
        else
            mods = bids.query(BIDS,'modalities');
        end
        %-Get optional target option for metadata query
        if strcmp(query,'metadata') && any(ismember(opts(:,1),'target'))
            target = opts{ismember(opts(:,1),'target'),2};
            opts(ismember(opts(:,1),'target'),:) = [];
            if iscellstr(target)
                target = substruct('.',target{1});
            end
        else
            target = [];
        end
        %-Perform query
        for i=1:numel(BIDS.subjects)                    
            if ~ismember(BIDS.subjects(i).name(5:end),subs), continue; end
            for j=1:numel(mods)
                d = BIDS.subjects(i).(mods{j});
                for k=1:numel(d)
                    sts = true;
                    for l=1:size(opts,1)
                        if ~isfield(d(k),opts{l,1}) || ~ismember(d(k).(opts{l,1}),opts{l,2})
                            sts = false;
                        end
                    end
                    switch query
                        case 'subjects'
                            if sts
                                result{end+1} = BIDS.subjects(i).name;
                            end
                        case 'sessions'
                            if sts
                                result{end+1} = BIDS.subjects(i).session;
                            end
                        case 'data'
                            if sts && isfield(d(k),'filename')
                                if strcmp(mods{j},'other')
                                    result{end+1} = fullfile(BIDS.subjects(i).path,d(k).filename);
                                else
                                    result{end+1} = fullfile(BIDS.subjects(i).path,mods{j},d(k).filename);
                                end
                            end
                        case 'metadata'
                            if sts && isfield(d(k),'filename')
                                f = fullfile(BIDS.subjects(i).path,mods{j},d(k).filename);
                                result{end+1} = get_metadata(f);
                                if ~isempty(target)
                                    try
                                        result{end} = subsref(result{end},target);
                                    catch
                                        warning('Non-existent field for metadata.');
                                        result{end} = [];
                                    end
                                end
                            end
%                             if sts && isfield(d(k),'meta')
%                                 result{end+1} = d(k).meta;
%                             end
                        case 'runs'
                            if sts && isfield(d(k),'run')
                                result{end+1} = d(k).run;
                            end
                        case 'tasks'
                            if sts && isfield(d(k),'task')
                                result{end+1} = d(k).task;
                            end
                        case 'types'
                            if sts && isfield(d(k),'type')
                                result{end+1} = d(k).type;
                            end
                    end
                end
            end
        end
        %-Postprocessing output variable
        switch query
            case 'subjects'
                result = unique(result);
                result = regexprep(result,'^[a-zA-Z0-9]+-','');
            case 'sessions'
                result = unique(result);
                result = regexprep(result,'^[a-zA-Z0-9]+-','');
                result(cellfun('isempty',result)) = [];
            case 'data'
                result = result';
            case 'metadata'
                if numel(result) == 1
                    result = result{1};
                end
            case {'tasks','runs','types'}
                result = unique(result);
                result(cellfun('isempty',result)) = [];
        end
    otherwise
        error('Unable to perform BIDS query.');
end


%==========================================================================
%-Parse BIDS query
%==========================================================================
function query = parse_query(query)
if numel(query) == 1 && isstruct(query{1})
    query = [fieldnames(query{1}), struct2cell(query{1})];
else
    if mod(numel(query),2)
        error('Invalid input syntax.');
    end
    query = reshape(query,2,[])';
end
for i=1:size(query,1)
    if ischar(query{i,2})
        query{i,2} = cellstr(query{i,2});
    end
    for j=1:numel(query{i,2})
        if iscellstr(query{i,2})
            query{i,2}{j} = regexprep(query{i,2}{j},sprintf('^%s-',query{i,1}),'');
        end
    end
end
