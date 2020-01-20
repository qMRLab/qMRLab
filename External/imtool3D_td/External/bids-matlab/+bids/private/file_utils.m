function varargout = file_utils(str,varargin)
% Character array (or cell array of strings) handling facility
% FORMAT str = file_utils(str,option)
% str        - character array, or cell array of strings
% option     - string of requested item - one among:
%              {'path', 'basename', 'ext', 'filename', 'cpath', 'fpath'}
%
% FORMAT str = file_utils(str,opt_key,opt_val,...)
% str        - character array, or cell array of strings
% opt_key    - string of targeted item - one among:
%              {'path', 'basename', 'ext', 'filename', 'prefix', 'suffix'}
% opt_val    - string of new value for feature
%__________________________________________________________________________
%
% Based on spm_file.m and spm_select.m from SPM12.
%__________________________________________________________________________

% Copyright (C) 2011-2018 Guillaume Flandin, Wellcome Centre for Human Neuroimaging


if ismember(lower(str), {'list','fplist'})
    [varargout{1:nargout}] = listfiles(str, varargin{:});
    return;
end

needchar = ischar(str);
options = varargin;

str = cellstr(str);

%-Get item
%==========================================================================
if numel(options) == 1
    for n=1:numel(str)
        [pth,nam,ext] = fileparts(deblank(str{n}));
        switch lower(options{1})
            case 'path'
                str{n} = pth;
            case 'basename'
                str{n} = nam;
            case 'ext'
                str{n} = ext(2:end);
            case 'filename'
                str{n} = [nam ext];
            case 'cpath'
                str(n) = cpath(str(n));
            case 'fpath'
                str{n} = fileparts(char(cpath(str(n))));
            otherwise
                error('Unknown option.');
        end
    end
    options = {};
end

%-Set item
%==========================================================================
while ~isempty(options)
    for n=1:numel(str)
        [pth,nam,ext] = fileparts(deblank(str{n}));
        switch lower(options{1})
            case 'path'
                pth = char(options{2});
            case 'basename'
                nam = char(options{2});
            case 'ext'
                ext = char(options{2});
                if ~isempty(ext) && ext(1) ~= '.'
                    ext = ['.' ext];
                end
            case 'filename'
                nam = char(options{2});
                ext = '';
            case 'prefix'
                nam = [char(options{2}) nam];
            case 'suffix'
                nam = [nam char(options{2})];
            otherwise
                warning('Unknown item ''%s'': ignored.',lower(options{1}));
        end
        str{n} = fullfile(pth,[nam ext]);
    end
    options([1 2]) = [];
end

if needchar
    str = char(str);
end
varargout = {str};


%==========================================================================
%-Canonicalise paths to full path names
%==========================================================================
function t = cpath(t,d)
% canonicalise paths to full path names, removing xxx/./yyy and xxx/../yyy
% constructs
% t must be a cell array of (relative or absolute) paths, d must be a
% single cell containing the base path of relative paths in t
if ispc % valid absolute paths
    % Allow drive letter or UNC path
    mch = '^([a-zA-Z]:)|(\\\\[^\\]*)';
else
    mch = '^/';
end
if (nargin<2)||isempty(d), d = {pwd}; end
% Find partial paths, prepend them with d
ppsel    = cellfun(@isempty, regexp(t,mch,'once'));
t(ppsel) = cellfun(@(t1)fullfile(d{1},t1),t(ppsel),'UniformOutput',false);
% Break paths into cell lists of folder names
pt = pathparts(t);
% Remove single '.' folder names
sd = cellfun(@(pt1)strcmp(pt1,'.'),pt,'UniformOutput',false);
for cp = 1:numel(pt)
    pt{cp} = pt{cp}(~sd{cp});
end
% Go up one level for '..' folders, don't remove drive letter/server name
% from PC path
if ispc
    ptstart = 2;
else
    ptstart = 1;
end
for cp = 1:numel(pt)
    tmppt = {};
    for cdir = ptstart:numel(pt{cp})
        if strcmp(pt{cp}{cdir},'..')
            tmppt = tmppt(1:end-1);
        else
            tmppt{end+1} = pt{cp}{cdir};
        end
    end
    if ispc
        pt{cp} = [pt{cp}(1) tmppt];
    else
        pt{cp} = tmppt;
    end
end
% Assemble paths
if ispc
    t = cellfun(@(pt1)fullfile(pt1{:}),pt,'UniformOutput',false);
else
    t = cellfun(@(pt1)fullfile(filesep,pt1{:}),pt,'UniformOutput',false);
end


%==========================================================================
%-Parse paths
%==========================================================================
function pp = pathparts(p)
% parse paths in cellstr p
% returns cell array of path component cellstr arrays
% For PC (WIN) targets, both '\' and '/' are accepted as filesep, similar
% to MATLAB fileparts
if ispc
    fs = '\\/';
else
    fs = filesep;
end
pp = cellfun(@(p1)textscan(p1,'%s','delimiter',fs,'MultipleDelimsAsOne',1),p);
if ispc
    for k = 1:numel(pp)
        if ~isempty(regexp(pp{k}{1}, '^[a-zA-Z]:$', 'once'))
            pp{k}{1} = strcat(pp{k}{1}, filesep);
        elseif ~isempty(regexp(p{k}, '^\\\\', 'once'))
            pp{k}{1} = strcat(filesep, filesep, pp{k}{1});
        end
    end
end


%==========================================================================
%-List files and directories
%==========================================================================
function [fi, di] = listfiles(action,d,varargin)
% FORMAT [files, dirs] = listfiles('List',dir,regexp)
% FORMAT [files, dirs] = listfiles('FPList',dir,regexp)
% FORMAT [dirs] = listfiles('List',dir,'dir',regexp)
% FORMAT [dirs] = listfiles('FPList',dir,'dir',regexp)

fi = '';
di = '';
switch lower(action)
    case 'list'
        fp = false;
    case 'fplist'
        fp = true;
    otherwise
        error('Invalid syntax.');
end
if nargin < 2
    d = pwd;
else
    d = file_utils(d,'cpath');
end
dirmode = false;
if nargin < 3
    expr = '.*';
else
    if strcmpi(varargin{1},'dir')
        dirmode = true;
        if nargin < 4
            expr = '.*';
        else
            expr = varargin{2};
        end
    else
        expr = varargin{1};
    end
end
dd = dir(d);
if isempty(dd)
    return;
end
fi = sort({dd(~[dd.isdir]).name})';
di = sort({dd([dd.isdir]).name})';
di = setdiff(di,{'.','..'});
if dirmode
    t = regexp(di,expr);
    if numel(di)==1 && ~iscell(t), t = {t}; end
    di = di(~cellfun(@isempty,t));
    fi = di;
else
    t = regexp(fi,expr);
    if numel(fi)==1 && ~iscell(t), t = {t}; end
    fi = fi(~cellfun(@isempty,t));
end
if fp
    fi = cellfun(@(x) fullfile(d,x), fi, 'UniformOutput',false);
    di = cellfun(@(x) fullfile(d,x), di, 'UniformOutput',false);
end
fi = char(fi);
di = char(di);
