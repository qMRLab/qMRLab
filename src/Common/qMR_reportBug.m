function qMR_reportBug(exception)
% report bug to the qMRLab dev team.
% Only reports errors that concern a qMRLab file
% Anonymize folders 
%
% example:
%   qMR_reportBug(MException.last)

if nargin<1, help('qMR_reportBug'); return; end
qMRLabDir = fileparts(which('qMRLab.m'));
qmrexcep = strfind({exception.stack.file},qMRLabDir);
if any(~cellfun(@isempty,qmrexcep))
    warning('qMRLab error detected');
    % remove directory
    buggyfiles = exception.stack;
    for ii=1:length(buggyfiles)
        if ~isempty(qmrexcep{ii})
            buggyfiles(ii).file = strrep(buggyfiles(ii).file,qMRLabDir,'qMRLabDir');
        else
            [~,buggyfiles(ii).file] = fileparts(buggyfiles(ii).file); 
        end
    end
    
    % create structure to be sent
    errortext.message = exception.message;
    errortext.identifier = exception.identifier;
    errortext.stack = buggyfiles;
    txt = savejson(errortext);
    
    Questions = {sprintf('OUPS... A BUG OCCURED\n\n1- Your Email (optional):') '2- Name / GitHub username (optional)' '3- Describe what happened (optional)' '4- Bug Content'};
    txt2send = inputdlg(Questions,'Report the following bug to the qMRLab dev team?',[1 30; 1 30; 10 200; 10 200],{'' '' sprintf('I was trying to ...\n\n...when the bug happened') [sprintf('qMRLab version: v%i.%i.%i\nMatlab version: %s\n\n',qMRLabVer,version) txt]});
    
    if ~isempty(txt2send)
        txt2send = Interleave(Questions,txt2send);
        txt=cellfun(@cellstr,txt2send,'uni',false)
        txt = cat(1,txt{:});
        txt = sprintf('%s\n',txt{:});
        disp('sending...')
        disp(txt)
        try
            % send error
            setpref('Internet','E_mail','qMRLabbugreport@company.com')
            setpref('Internet','SMTP_Server','mail.smtp2go.com')
            
            props = java.lang.System.getProperties;
            props.setProperty('mail.smtp.auth','true');
            
            setpref('Internet','SMTP_Username','qMRLabBugReport');
            setpref('Internet','SMTP_Password','E3dUgoH4101M');

            sendmail('qmrlab_developers@googlegroups.com','qMRLab issue',txt);
        catch ME2
            warning('Notifier:SendmailError','Sendmail threw an error. Check sendmail before running again.');
            warning('Nofifier:SendmailError',ME2.message);
        end
    else
        disp('not reporting error...')
    end
    
else
    warning('last error is not a qMRLab error');
end
