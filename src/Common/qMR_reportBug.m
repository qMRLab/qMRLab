function qMR_reportBug(exception)
% report bug to the qMRLab dev team.
% Only reports errors that concern a qMRLab file
% Anonymize folders 
%
% example:
%   qMR_reportBug(MException.last)

persistent err
if isempty(err), err={}; end
knownerror = cell2mat(cellfun(@(x) isequal(exception,x),err,'uni',0));
if any(knownerror)
    disp('error already reported. return. (''clear all'' variables to reset error history)')
    return;
else
    err{end+1} = exception;
end

if nargin<1, help('qMR_reportBug'); return; end
qMRLabDir = fileparts(which('qMRLab.m'));
qmrexcep = strfind({exception.stack.file},qMRLabDir);
if any(~cellfun(@isempty,qmrexcep))
    warning('qMRLab error detected');
    buggyfiles = exception.stack;
    % keep only qMRLab errors
    buggyfiles = buggyfiles(logical(cell2mat(qmrexcep)));
    % remove directory

    for ii=1:length(buggyfiles)
        buggyfiles(ii).file = [strrep(strrep(buggyfiles(ii).file,qMRLabDir,'https://github.com/qMRLab/qMRLab/blob/master'),filesep,'/') '#L' num2str(buggyfiles(ii).line)];
    end
    
    % create structure to be sent
    message = exception.message;
    stack = sprintf('%s\n',buggyfiles.file);
    stack = strrep(stack,'\/','/');
    body  = sprintf(['qMRLab version: v%i.%i.%i\n',...
                     'Matlab version: %s\n\n',...
                     'Error message:\n',...
                     '`%s`\n',...
                     '\nStack:\n',...
                     '%s\n'],...
                     qMRLabVer,version,message,stack);
    body = urlencode(body);
    title = '[USER]';
    
    % report
    answer = questdlg('Report Bug on GitHub?','OUPS... A BUG OCCURED','Yes','No','Yes');    
    if strcmp(answer,'Yes')
        try
            web(['https://github.com/qMRLab/qMRLab/issues/new?assignees=&labels=bug&body=' body '&title=' title], '-browser')
        catch ME2
            warning('Nofifier:webError','%s',ME2.message);
        end
    else
        disp('not reporting error...')
    end
    
else
    warning('last error is not a qMRLab error');
end
