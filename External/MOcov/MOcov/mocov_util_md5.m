function md5=mocov_util_md5(filename)
% return the md5sum from the contents of a file
%
% md5=mocov_util_md5(filename)
%
% Inputs:
%   filename            name of file for which md5 must be computed
%
% Output:
%   md5                 md5 checksum of the contents of the file filename
%
% Notes:
%    - this function requires either the presence of a function named
%      'md5sum' (available on the GNU Octave platform), or the usage of a
%      unix-like platform
%
%
    md5_with_whitespace=md5_from_file(filename);
    md5=regexprep(md5_with_whitespace,'\s','');%


function md5=md5_from_file(fn)
    md5_processors={@md5_builtin,...
                    @hash_builtin,...
                    @md5sum_shell,...
                    @md5_shell};

    n=numel(md5_processors);
    for k=1:n
        md5_processor=md5_processors{k};
        [is_ok,md5]=md5_processor(fn);
        if is_ok
            return;
        end
    end

    error('Unable to compute md5 - no method available');

function [is_ok,md5]=md5_builtin(fn)
% supported in GNU Octave <= 4.6
    is_ok=has_builtin_function('md5sum');
    if is_ok
        md5=md5sum(fn);
    else
        md5=[];
    end


function [is_ok,md5]=hash_builtin(fn)
% supported in GNU Octave >= 4.4

    is_ok=has_builtin_function('hash') && has_builtin_function('fileread');
    if is_ok
        md5=hash('md5',fileread(fn));
    else
        md5=[];
    end

function tf=has_builtin_function(name)
    tf=exist(name,'builtin');

function [is_ok,md5]=run_unix(cmd)
% helper function
    is_ok=false;
    md5=[];

    if ispc()
        return;
    end

    [status,md5]=unix(cmd);
    is_ok=status==0;

function [is_ok,md5]=md5sum_shell(fn)
% supported on Unix platform

    cmd=sprintf('md5sum "%s"',fn);
    [is_ok,md5_with_fn]=run_unix(cmd);
    parts=regexp(md5_with_fn,'\s+','split');
    md5=parts{1};


function [is_ok,md5]=md5_shell(fn)
% supported on Unix platform

    cmd=sprintf('md5 -q "%s"',fn);
    [is_ok,md5]=run_unix(cmd);

