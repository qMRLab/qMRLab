function [status] = versionChecker
status = [];
cur_ver = qMRLabVer;
cprintf('magenta','----------------%s','-------------------------------');
cprintf('magenta','Release v%d.%d.%d',cur_ver(1),cur_ver(2),cur_ver(3));
% Check if online

% This is so far the most xross compatible option
command=['curl --silent ','"','https://api.github.com/repos/qmrlab/qmrlab/license','"'];
[isOnline,~]=system(command);

if isOnline==0 % Connected
        if moxunit_util_platform_is_octave
            if compare_versions(OCTAVE_VERSION,'6.0.0','<') 
              command=['curl --silent ','"','https://api.github.com/repos/qmrlab/qmrlab/releases/latest','"'];
              [~,response]=system(command);
            else % From Octave 6 on, this is OK (but the output is still string, not formatted similar to that of curl)
              response = webread('https://api.github.com/repos/qmrlab/qmrlab/releases/latest');
            end
        else
            response = webread('https://api.github.com/repos/qmrlab/qmrlab/releases/latest');
        end
    if ~isempty(response)
        if ~moxunit_util_platform_is_octave
            latest_ver = regexp(response.tag_name, 'v(\d*)\.(\d*).(\d*)?', 'tokens');
        else
            % Octave does not convert web response into struct right away.
            latest_ver = regexp(response, '"tag_name":"v(\d*)\.(\d*).(\d*)?', 'tokens');
            % Try other format
            if isempty(latest_ver); latest_ver = regexp(response, '"tag_name": "v(\d*)\.(\d*).(\d*)?', 'tokens'); end
        end
        latest_ver = str2double(latest_ver{1});
        if any((qMRLabVer-latest_ver)<0) % Using an older version
           cprintf('magenta','There is a newer version available for  %s','download!');
           if ~moxunit_util_platform_is_octave
             cprintf('magenta','Click %s to download the latest qMRLab release v%d.%d.%d.','<a href = "https://github.com/qMRLab/qMRLab/releases/latest">here</a>',latest_ver(1),latest_ver(2),latest_ver(3));
           else
             cprintf('magenta','You can download the latest qMRLab release v%d.%d.%d at: %s',latest_ver(1),latest_ver(2),latest_ver(3),'https://github.com/qMRLab/qMRLab/releases/latest');               
           end
           status = latest_ver;
        elseif sum(qMRLabVer-latest_ver) == 0 % Using latest
           % Cheer up dedicated users :)  
           emoji = [ 40   239   190   137   226   151   149   227   131   174   226   151   149    41   239   190   137    42    58   239   189   165 239 190 159]; 
           try
           cprintf('magenta','%s You are running the latest version of %s',native2unicode(emoji,'UTF-8'),'qMRLab!');
           catch
            cprintf('magenta','%s You are running the latest version of %s','qMRLab!');              
           end
        else % Development branch
           emoji = [224   178   160    95   224   178   160];
           try
           cprintf('blue','%s The version specified in version.txt is ahead of the latest published release v%d.%d.%d.',native2unicode(emoji,'UTF-8'),latest_ver(1),latest_ver(2),latest_ver(3));
           catch
           cprintf('blue','%s The version specified in version.txt is ahead of the latest published release v%d.%d.%d.','Hawdy developer! ',latest_ver(1),latest_ver(2),latest_ver(3)); 
           end
           cprintf('magenta','Please do not forget pushing a new commit tag upon merge or publish the %s','new release.') ;
        end
    end
end
cprintf('magenta','----------------%s','-------------------------------');
end