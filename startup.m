
addpath(genpath(pwd));

% ======================================== TRAVIS CACHE SELECTION

% Set <<cahceState>> to:

%  <false> if cache (for octave packages) is cleared
%  <true> if the same cache (for octave packages) is still in use

cacheState = false;
% -----------------------------------------------------

if moxunit_util_platform_is_octave
    if ~cacheState
        more off;
        installist = {'struct-1.0.14.tar.gz','optim-1.5.2.tar.gz','io-2.4.10.tar.gz','statistics-1.3.0.tar.gz','image-2.6.1.tar.gz'};
        loadlist = {'struct','optim','io','statistics','image'};
        cd('/home/travis/octave');
        for ii=1:length(installist)
            pkg prefix '/home/travis/octave'
            pkg local_list '/home/travis/octave/.octave_packages'
            try
                disp(['Installing --> ' installist{ii}])
                eval(['pkg install ' installist{ii}])
                disp(['Loading -->' loadlist{ii}])
                eval(['pkg load ' loadlist{ii}])
            catch
                errorcount = 1;
                while errorcount % try to install 30 times (Travis)
                    try
                        eval(['pkg install ' installist{ii}])
                        eval(['pkg load ' loadlist{ii}])
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
        
        addpath(genpath('/home/travis/octave'));
      
        pkg list
        unix('ls /home/travis/octave')
        chk = test('lsqcurvefit');
        
        if ~chk
            error('Lsqcurvefit could not be loaded properly');
        end
        
    elseif cacheState
        
        addpath(genpath('/home/travis/octave'));
        
        pkg prefix '/home/travis/octave';
        pkg local_list '/home/travis/octave/.octave_packages';
        loadlist = {'struct','optim','io','statistics','image'};
        for ii=1:length(loadlist)
            try
                disp(['Loading -->' loadlist{ii}])
                eval(['pkg load ' loadlist{ii}])
            catch err
                disp(err);
            end
        end
        pkg list % See the list of installed packages
        chk = test('lsqcurvefit');
        if ~chk
            error('Lsqcurvefit could not be loaded properly');
        end
        %unix('lscpu'); % Check processor allowance on remote server
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
        error('Cannot compile External/Faddeeva_MATLAB, a function used by NODDI. Plz install a compiler and run Faddeeva_build. Alternatively, edit NODDI_erfi.')
    end
end