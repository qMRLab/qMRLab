function p = parse_filename(filename,fields)
% Split a filename into its building constituents
% FORMAT p = parse_filename(filename,fields)
%
% Example:
%
% >> filename = '../sub-16/anat/sub-16_ses-mri_run-1_echo-2_FLASH.nii.gz';
% >> parse_filename(filename)
%
% ans = 
%
%   struct with fields:
%
%     filename: 'sub-16_ses-mri_run-1_echo-2_FLASH.nii.gz'
%         type: 'FLASH'
%          ext: '.nii.gz'
%          sub: '16'
%          ses: 'mri'
%          run: '1'
%         echo: '2'
%__________________________________________________________________________

% Copyright (C) 2016-2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2018--, BIDS-MATLAB developers

filename = file_utils(filename,'filename');
[parts, dummy] = regexp(filename,'(?:_)+','split','match');
p.filename = filename;
[p.type, p.ext] = strtok(parts{end},'.');
for i=1:numel(parts)-1
    [d, dummy] = regexp(parts{i},'(?:\-)+','split','match');
    if length(d)<2
%        warning([filename ' cannot be parsed. ''' d{1} ''' is not associated with a label (' d{1} '-)']);
        continue
    end
    p.(d{1}) = d{2};
end
if nargin == 2
    for i=1:numel(fields)
        if ~isfield(p,fields{i})
            p.(fields{i}) = '';
        end
    end
    try
        p = orderfields(p,['filename','ext','type',fields]);
    catch
        warning('Ignoring file "%s" not matching template.',filename);
        p = struct([]);
    end
end
