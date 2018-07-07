addpath(genpath(pwd))

if ~moxunit_util_platform_is_octave % MATLAB
    % Test Optimization toolbox is installed
    if ~license('test', 'Optimization_Toolbox'), error('Optimization_Toolbox is missing... most model won''t fit. Consider installing <a href="matlab:matlab.internal.language.introspective.showAddon(''OP'');">Optimization Toolbox</a>'); end
    
else % OCTAVE
    % install octave package
    installlist = {'struct','optim','io','statistics','image'};
    for ii=1:length(installlist)
        try
            disp(['loading ' installlist{ii}])
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
    NODDI_erfi(.8);
catch
    % Compile Faddeeva
    cur = pwd;
    cd(fullfile(fileparts(mfilename('fullpath')),'External','Faddeeva_MATLAB'))
    try
        disp('Compile Faddeeva...')
        Faddeeva_build
        disp('                ...ok')
        cd(cur)
    catch
        cd(cur)
        if moxunit_util_platform_is_octave
            error('Cannot compile External/Faddeeva_MATLAB.m, a function used by NODDI (in NODDI_erfi.m). Plz install a compiler (https://fr.mathworks.com/support/compilers.html) and run startup.m again.')
        else
            warning('NODDI IS SLOW: Cannot compile External/Faddeeva_MATLAB.m, a fast function used by NODDI (in NODDI_erfi.m). Plz install a compiler (https://fr.mathworks.com/support/compilers.html) and run startup.m again.')
        end
    end
end