addpath(genpath(pwd))

% install octave package
if moxunit_util_platform_is_octave
    installlist = {'struct','optim','io','statistics'};
    for ii=1:length(installlist)
        try
            pkg('load',installlist{ii})
        catch
            errorcount = 1;
            while errorcount % try to install 30 times (Travis)
                try
                    pkg('install','-forge',installlist{ii})
                    pkg('load',installlist{ii})
                    errorcount = 0;
                catch err
                    errorcount = errorcount+1;
                    if errorcount>30
                        error(err.message)
                    end
                end
            end
        end
    end
end

try
    erfi(.8);
catch
    cur = pwd;
    cd(fullfile(fileparts(mfilename('fullpath')),'External','Faddeeva_MATLAB'))
    Faddeeva_build
    cd(cur)
end