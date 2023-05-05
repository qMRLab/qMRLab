function usrpreferences = saveUserPreferences(usrpreferences)

    qMRLabDir = fileparts(which('qMRLab.m'));
    savejson([],usrpreferences,fullfile(qMRLabDir,'usr','preferences.json'));
    cprintf('orange',    '<< i >> User preferences have been %s \n','updated');
    
end