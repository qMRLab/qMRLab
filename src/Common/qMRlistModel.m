function list = qMRlistModel
if nargout, list = list_models; end
for im = list_models'
    header=qMRinfo(im{:}); % not compatible with octave
    if moxunit_util_platform_is_octave, return; end
    % get the first line
    ind = strfind(header,sprintf('\n'));
    header = header(1:ind-1);
    % remove space
    header = header(find(~isspace(header),1,'first'):end);
    % add tab after colons
    indcolons = strfind(header,':');
    header = ['<strong>' header(1:indcolons) '</strong>' repmat(' ',[1 max(1,30 - indcolons)]) header((indcolons+find(~isspace(header(indcolons+1:end)),1,'first')):end)];
    disp(header)
end