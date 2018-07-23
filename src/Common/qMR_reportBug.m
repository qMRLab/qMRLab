function qMR_reportBug(exception)
% report bug to the qMRLab dev team.
% Only reports errors that concern a qMRLab file
% Anonymize folders 
%
% example:
%   qMR_reportBug(MException.last)

if nargin<1, help('qMR_reportBug'); end
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
    
    [res, txt2send] = qstdialogedittxt('title','Bug Report','String',txt);
    if strcmpi(res,'yes')
        % send error
        setpref('Internet','E_mail','qMRLabbugreport@company.com')
        setpref('Internet','SMTP_Server','mail')
        txt = {}; for ii=1:size(txt2send,1), txt{ii} = txt2send(ii,:); end
        sendmail('qmrlab_developers@googlegroups.com','qMRLab issue',sprintf('%s\n',txt{:}))
    else
        disp('not reporting error...')
    end
    
else
    warning('last error is not a qMRLab error');
end
