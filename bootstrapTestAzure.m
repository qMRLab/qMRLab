
addpath(genpath(pwd));
crDir = pwd;

if moxunit_util_platform_is_octave
    
        more off;
        %installist = {'struct-1.0.14.tar.gz','io-2.4.10.tar.gz','statistics-1.3.0.tar.gz',%'optim-1.5.2.tar.gz','image-2.6.1.tar.gz'};
        %loadlist = {'struct','io','statistics','optim','image'};
        %cd('/home/agah_local/octave');
        %for ii=1:length(installist)
        %    pkg prefix '/home/agah_local/octave'
        %    pkg local_list '/home/agah_local/octave/.octave_packages'
        %    try
        %        disp(['Installing --> ' installist{ii}])
        %        eval(['pkg install ' installist{ii}])
        %        disp(['Loading -->' loadlist{ii}])
        %        eval(['pkg load ' loadlist{ii}])
        %    catch
        %        errorcount = 1;
        %        while errorcount % try to install 30 times (Travis)
        %            try
        %                eval(['pkg install ' installist{ii}])
        %                eval(['pkg load ' loadlist{ii}])
        %                errorcount = 0;
        %            catch err
        %                errorcount = errorcount+1;
        %                if errorcount>30
        %                    error(err.message)
        %                end
        %            end
        %        end
        %    end
        % end
        
        packs = pkg('list');
        for jj = 1:numel(packs)
        disp(['loading ' packs{jj}.name]);
        pkg('load', packs{jj}.name);
        end

        addpath(genpath('/home/agah_local/octave'));
      
        pkg list
        unix('ls /home/agah_local/octave')
        chk = test('lsqcurvefit');
        
        if ~chk
            error('Lsqcurvefit could not be loaded properly');
        end
        
        cd(crDir);
    
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
