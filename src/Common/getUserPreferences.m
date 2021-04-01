function usrpreferences = getUserPreferences()

  if ~isempty(getenv('ISBIDS'))
    if strcmp(getenv('ISBIDS'),'1')
       ISBIDS = true; 
    else
      ISBIDS = false;
    end
  else
    ISBIDS = false;
  end

try
  qMRLabDir = fileparts(which('qMRLab.m'));
  usrpreferences = json2struct(fullfile(qMRLabDir,'usr','preferences.json'));
  % If user overrides their own preferences with BIDS conventions 
  % or qMRLab signals that it needs BIDS units, the following fields
  % will respect BIDS: 
  % - UnifyOutputMapUnits 
  % - UnifyInputProtocolUnits
  % - ChangeProvidedInputMapUnits

  if usrpreferences.ForAllUnitsUseBIDS || ISBIDS
    bidsPreferences = json2struct(fullfile(qMRLabDir,'dev','bids_specification','units_BIDS_preferences.json'));
    
    % Warn user that some of their Enabled configs will be overriden because they ENABLED BIDS
    if usrpreferences.ForAllUnitsUseBIDS
      if any([usrpreferences.UnifyOutputMapUnits.Enabled, usrpreferences.UnifyInputProtocolUnits.Enabled,usrpreferences.ChangeProvidedInputMapUnits.Enabled ])
        cprintf('red',   '<< ! >> Overriding user unit preferences: ForAllUnitsUseBIDS is %s \n','enabled.');
        cprintf('blue',   '<< i >> To silence this warning set Enabled option to %s \n','false in /usr/preferences.json for the following fields:');
        cprintf('magenta',   '        - UnifyOutputMapUnits  \n',' ');
        cprintf('magenta',   '        - UnifyInputProtocolUnits  \n',' ');
        cprintf('magenta',   '        - ChangeProvidedInputMapUnits  \n',' ');
      end
    end

    % Override user settings with BIDS settings
    usrpreferences.UnifyOutputMapUnits = bidsPreferences.UnifyOutputMapUnits;
    usrpreferences.UnifyInputProtocolUnits = bidsPreferences.UnifyInputProtocolUnits;
    usrpreferences.ChangeProvidedInputMapUnits = bidsPreferences.ChangeProvidedInputMapUnits;

  end
catch me
   infomsg = me.message;
   cprintf('red',   '----------------------------------------- %s \n','-');
   cprintf('red',    '<< Exception >> Exception msg: %s \n','');
   disp(infomsg);
   cprintf('red',   '----------------------------------------- %s \n','-');
   cprintf('red',    '<< ! >> Assuming parsing error: %s \n',fullfile(qMRLabDir,'usr','preferences.json'));
   cprintf('blue',   '<< i >> Please ensure that %s is a valid json file (https://jsonformatter.org/) \n','/usr/preferences.json');
   cprintf('magenta',    '<< @ >> Defaulting to qMRLab''s original preferences (stored online at %s) \n','https://raw.githubusercontent.com/qMRLab/qMRLab/master/usr/preferences.json');
   usrpreferences = json2struct(urlread('https://raw.githubusercontent.com/qMRLab/qMRLab/master/usr/preferences.json'));
end

end