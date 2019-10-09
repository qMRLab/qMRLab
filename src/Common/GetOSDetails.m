function details = GetOSDetails
  
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
                details = rmUserInfoOSX(out);
             
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

function out = rmUserInfoOSX(ipt)

    usridx = strfind(ipt,'User Name');
    pcidx = strfind(ipt,'Computer Name');
    nwlines = strfind(ipt,char(10));
   
    if ~isempty(usridx)
    ipt = hideUser(usridx,nwlines,ipt);
    end
    
    if ~isempty(pcidx)
    ipt = hideUser(pcidx,nwlines,ipt);
    end

    out = ipt;

end

function out = hideUser(idx,nwlines,ipt)

    tmp = nwlines - idx;
    tmp = min(tmp(tmp>0));
    interval = idx:idx+min(tmp)-1;

    ipt(interval) = '*';
    ipt(max(interval)+1) = char(10);

    out = ipt;
end