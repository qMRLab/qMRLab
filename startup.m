addpath(genpath(pwd))

% install octave package
if moxunit_util_platform_is_octave
    try
        pkg load optim
    catch
        pkg install -forge struct
        pkg install -forge optim
        pkg load optim
    end
    try
        pkg load statistics
    catch
        pkg install -forge io
        pkg install -forge statistics
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