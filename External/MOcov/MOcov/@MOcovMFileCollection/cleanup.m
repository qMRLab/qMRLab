function cleanup(obj)
% remove temporary files created by prepare
%
% cleanup(obj)
%
% Inputs:
%   obj                 MOcovMFileCollection instance
%
% Notes:
% - this function should be called after coverage has been determined.
%
% See also: rewrite_mfiles, prepare

    notify(obj.monitor,'Cleanup');
    if ~isempty(obj.orig_path)
        notify(obj.monitor,'','Resetting path');
        path(obj.orig_path);
    end

    if ~isempty(obj.temp_dir)
        msg=sprintf('Removing temporary files in %s',obj.temp_dir);
        notify(obj.monitor,'',msg);

        if mocov_util_platform_is_octave()
            % GNU Octave requires, by default, confirmation when using
            % rmdir. The state of confirm_recursive_rmdir is stored,
            % and set back to its original value when leaving this
            % function.
            confirm_val=confirm_recursive_rmdir(false);
            cleaner=onCleanup(@()confirm_recursive_rmdir(confirm_val));
        end

        rmdir(obj.temp_dir,'s');
    end
