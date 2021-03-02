function test_suite=getSetPreferencesTest
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;
    
    function test_getPreferences
    disp('Get user preferences from local json');
    usrpreferences_orig = getUserPreferences();
    disp('Mess up usr preferences file');
    qMRLabDir = fileparts(which('qMRLab.m'));
    jsonfile = fullfile(qMRLabDir,'usr','preferences.json');

    fileID = fopen(jsonfile,'r');
    prf = fscanf(fileID,'%s');
    % Remove commas, which will definetely invalidate the json
    prf(strfind(prf,','))=[];
    fclose(fileID);
    % Overwrite the existing one 
    fileID = fopen(jsonfile,'w');
    fprintf(fileID,'%s\n',prf);
    fclose(fileID);
    % Re-attempt by reading the preferences from GitHub
    usrpreferences_on_fail = getUserPreferences();
    % Revert 
    saveUserPreferences(usrpreferences_orig);

    disp('Done...');