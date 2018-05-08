function root_dir=mocov_util_get_root_path_containing(needle,child_dir)
% finds the nearest parent directory that contains a particular directory
%
% root_dir=mocov_util_get_root_path_containing(needle,child_dir)
%
% Inputs:
%   needle              subdirectory to look for
%   child_dir           starting directory
%
% Output:
%   rootdir             directory that contains needle and is a parent
%                       directory of child_dir. If multiple such
%                       directories exist, then the one with the longest
%                       absolute path is taken
%
% Notes:
% - this function is used by get_coverage_json to find the .git directory
%   of a repository
%
    if nargin<2
        child_dir=pwd();
    end

    root_dir=helper_get_root_dir_containing(needle,child_dir);

function root_path=helper_get_root_dir_containing(needle,child_dir)
    while true
        if has_in_dir(needle,child_dir)
            root_path=child_dir;
            return;
        end

        parent_dir=fileparts(child_dir);
        if isequal(child_dir,parent_dir)
            error('Unable to find file or directory %s',needle);
        end

        child_dir=parent_dir;
    end

function tf=has_in_dir(needle, child_dir)
    d=dir(child_dir);

    names={d.name};

    tf=~isempty(strmatch(needle,names,'exact'));


