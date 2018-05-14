function res=mocov_find_files(root_dir, file_pat, monitor, exclude_pat)
% Finds files recursively in a directory
%
% res=mocov_find_files([root_dir[, file_pat]])
%
% Inputs:
%   root_dir            Optional directory in which files are sought.
%                       If not provided or empty, the current working
%                       directory is used.
%   file_pat            Optional wildcard pattern, e.g. '*.m' for all
%                       files ending with '.m'. If omitted, the pattern '*'
%                       is used, corresponding to all files.
%   monitor             Optional progress monitory that supports a
%                       'notify' method.
%   exclude_pat         Optional cell array of patterns to exclude. Both
%                       files and directories which match one of these
%                       patterns will be omitted from the output.
%
% Output:
%   res                 Kx1 cell with names of files in root_dir matching
%                       the pattern.
%
% NNO May 2015

    if nargin<1
        root_dir='';
    end

    if ~(isempty(root_dir) || isdir(root_dir))
        error('first argument must be directory');
    end

    if nargin<2
        file_pat='*';
    end

    if nargin<3
        monitor=[];
    end

    if nargin<4
        exclude_pat={};
    end

    if ischar(exclude_pat)
        exclude_pat={exclude_pat};
    end

    file_re=pattern2re(file_pat);
    exclude_re=get_exclude_re(exclude_pat);

    if ~isempty(monitor)
        msg=sprintf('Finding files matching %s from %s',file_pat,root_dir);
        notify(monitor, msg);
    end

    res=find_files_recursively(root_dir,file_re,monitor,exclude_re);


function re=pattern2re(pat)
    re=['^' ... % start of the string
        regexptranslate('wildcard',pat) ...
        '$'];   % end of the string

function re=get_exclude_re(exclude_pat)
    n=numel(exclude_pat);
    if n==0
        re='';
        return;
    end

    excl_re_cell=cellfun(@pattern2re,exclude_pat,...
                        'UniformOutput',false);

    joined=sprintf('|%s',excl_re_cell{:});
    re=joined(2:end);


function res=find_files_recursively(root_dir,file_re,monitor,exclude_re)
    if isempty(root_dir)
        dir_arg={};
    else
        dir_arg={root_dir};
    end

    d=dir(dir_arg{:});
    n=numel(d);

    res_cell=cell(n,1);
    for k=1:n
        fn=d(k).name;

        ignore_fn=strcmp(fn,'.') || strcmp(fn,'..');

        res=cell(0,1);
        if ~ignore_fn
            path_fn=fullfile(root_dir, fn);

            if ~isempty(regexp(fn,exclude_re,'once'));
                continue;
            elseif isdir(path_fn)
                res=find_files_recursively(path_fn,file_re,...
                                                monitor,exclude_re);
            elseif ~isempty(regexp(fn,file_re,'once'));
                res={path_fn};
                if ~isempty(monitor)
                    notify(monitor,'.',path_fn);
                end
            end
        end
        res_cell{k}=res;
    end

    res_cell=res_cell(~cellfun('isempty',res_cell));
    res=cat(1,res_cell{:});
