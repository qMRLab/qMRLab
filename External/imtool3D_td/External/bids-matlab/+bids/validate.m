function [sts, msg] = validate(root)
% BIDS Validator
% FORMAT [sts, msg] = bids.validate(root)
% root    - directory formated according to BIDS [Default: pwd]
% sts     - 0 if successful
% msg     - warning and error messages
%__________________________________________________________________________
%
% Command line version of the BIDS-Validator:
%   https://github.com/bids-standard/bids-validator
%
% Web version: 
%   https://bids-standard.github.io/bids-validator/
%__________________________________________________________________________

% Copyright (C) 2018, Guillaume Flandin, Wellcome Centre for Human Neuroimaging
% Copyright (C) 2018--, BIDS-MATLAB developers


[sts, msg] = system('bids-validator --version');
if sts
    msg = 'Require bids-validator from https://github.com/bids-standard/bids-validator';
else
    [sts, msg] = system(['bids-validator "' strrep(root,'"','\"') '"']);
end
