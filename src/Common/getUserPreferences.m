function usrpreferences = getUserPreferences()

try
  qMRLabDir = fileparts(which('qMRLab.m'));
  usrpreferences = json2struct(fullfile(qMRLabDir,'usr','preferences.json'));
catch
   cprintf('red',    '<< ! >> Parsing error: %s \n',fullfile(qMRLabDir,'usr','preferences.json'));
   cprintf('blue',   '<< i >> Please ensure that %s is a valid json file (https://jsonformatter.org/) \n','/usr/preferences.json');
   cprintf('magenta',    '<< @ >> Defaulting to qMRLab''s original preferences (stored online at %s) \n','https://raw.githubusercontent.com/qMRLab/qMRLab/master/usr/preferences.json');
   usrpreferences = json2struct(urlread('https://raw.githubusercontent.com/qMRLab/qMRLab/master/usr/preferences.json'));
end

end