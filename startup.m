if ~isdeployed
addpath(genpath(fileparts(mfilename('fullpath'))))

try
        [~] = versionChecker;
catch
        qMRLabVer;
end


% Remove temp temp dir from path if it exists
tmpDir = fullfile(pwd, 'tmp');
if exist(tmpDir, 'dir')
    rmpath(genpath(tmpDir))
end


if ~moxunit_util_platform_is_octave % MATLAB
    % Test Optimization toolbox is installed
    if isempty(getenv('ISAZURE')) || ~str2double(getenv('ISAZURE')) 
        ISAZURE=false; 
    else
        ISAZURE=true; 
    end
    if ~ISAZURE
      if ~license('test', 'Optimization_Toolbox'), error('Optimization Toolbox is not installed on your system: most qMR models won''t fit. Please consider installing <a href="matlab:matlab.internal.language.introspective.showAddon(''OP'');">Optimization Toolbox</a> if you want to use qMRLab in MATLAB.'); end
      if ~license('test', 'Image_Toolbox'), warning('Image Toolbox is not installed: ROI Analysis tool not available in the GUI. Consider installing <a href="matlab:matlab.internal.language.introspective.showAddon(''IP'');">Image Processing Toolbox</a>'); end
    else
      disp('Please ignore the message about the missing toolbox in Azure pipelines.');
    end
else % OCTAVE
    % install octave packags
    installlist = {'struct','io','statistics','optim','image'};
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
end
end

addpath(genpath(fullfile(matlabroot,'toolbox','plotly')),'-end');