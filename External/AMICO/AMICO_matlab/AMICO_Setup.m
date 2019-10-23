%
% Initialization for AMICO
%
% NB: DO NOT MODIFY THIS FILE!
%     Make a copy of it, adapt to your paths and rename it to "AMICO_Setup.m"
%

global AMICO_code_path AMICO_data_path

% Path definition: adapt these to your needs
% ==========================================
AMICO_code_path = fileparts(mfilename('fullpath'));
AMICO_data_path = fullfile(AMICO_code_path,'exports');
if(~exist(AMICO_data_path,'dir'))
    mkdir(AMICO_data_path);
end