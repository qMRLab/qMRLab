function FitProvenanceSave
    
    FitProvenance = struct();
    
    if moxunit_util_platform_is_octave
        
        FitProvenance.Date = strftime('%Y-%m-%d %H:%M:%S', localtime (time ()));
        [FitProvenance.OS, FitProvenance.MaxSize, FitProvenance.Endian] = computer;
        FitProvenance.OSDetails = getOSDetails();
        FitProvenance.Platform = ['Octave ' OCTAVE_VERSION()];
        Fitprovenance.OctavePackages = pkg('list');
        FitProvenance.OctaveDetails = __octave_config_info__;
        
        save('-mat7-binary','FitProvenance.mat','FitProvenance');
        
    else 
        
        FitProvenance.Date = datetime(now,'ConvertFrom','datenum');
        [FitProvenance.OS, FitProvenance.MaxSize, FitProvenance.Endian] = computer; 
        FitProvenance.OSDetails = getOSDetails();
        FitProvenance.Platform = ['Matlab ' version('-release')];
        FitProvenance.PlatformDetails = ver;
        
        save('FitProvenance.mat','FitProvenance');
    end
    
end


function details = getOSDetails
    
    type = computer;

    if moxunit_util_platform_is_octave
        
        if ~isempty(strfind(type,'apple')) % OSX Octave 
            
            [st,out] = unix('cat /etc/os-release');
            
            if ~st
                details = out;
            else
                details = [];
            end
            
        end
        
        if ~isempty(strfind(type,'linux')) % GNU Linux Octave 
            
            [st,out] = unix('system_profiler SPSoftwareDataType');
            
            if ~st
                details = out;
            else
                details = [];
            end
            
        end
        
        if ~isempty(strfind(type,'windows')) % GNU Linux Octave 
            
            [st,out] = system('winver');
            
            if ~st
                details = out;
            else
                details = [];
            end
            
        end
        
    else % MATLAB 
        
        if strncmp(type,'MAC',3)
            
            [st,out] = unix('system_profiler SPSoftwareDataType');
            
            if ~st
                details = out;
            else
                details = [];
            end
            
        end
        
        if strncmp(type,'GLNX',4)
            
            [st,out] = unix('cat /etc/os-release');
            
            if ~st
                details = out;
            else
                details = [];
            end
            
        end
        
        if ~isempty(strfind(type,'WIN'))
            
            [st,out] = system('winver');
            
            if ~st
                details = out;
            else
                details = [];
            end
            
        end
        
        
    end
end