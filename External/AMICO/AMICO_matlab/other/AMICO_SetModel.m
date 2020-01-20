%
% Set the default parameters for each model
%
function AMICO_SetModel( model )

    global CONFIG

    CONFIG.model   = [];

    CONFIG.OPTIMIZATION = [];
    CONFIG.OPTIMIZATION.LS_param    = optimset('TolX',1e-4);
    CONFIG.OPTIMIZATION.SPAMS_param = [];

    % Call the specific model constructor
    modelClass = str2func( ['AMICO_' upper(model)] );
    if exist([func2str(modelClass) '.m'],'file')
        CONFIG.model = modelClass();
    else
        error( '[AMICO_SetModel] Model "%s" not recognized', model )
    end

end
