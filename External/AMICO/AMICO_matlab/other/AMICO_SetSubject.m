%
% Set the default parameters for a specific experiment (protocol/subject)
%
% Parameters
% ----------
% protocol : string
%   Folder for a specific acquisition protocol, possible containing different subjects
% subject : string
%   Folder of the specific subject
%
function AMICO_SetSubject( protocol, subject )

	global AMICO_data_path
	global CONFIG

	CONFIG = [];

	CONFIG.protocol			= protocol;
	CONFIG.subject			= subject;

	CONFIG.DATA_path		= fullfile( AMICO_data_path, CONFIG.protocol, CONFIG.subject );
	CONFIG.dwiFilename		= fullfile( CONFIG.DATA_path, 'DWI.nii' );
	CONFIG.maskFilename     = fullfile( CONFIG.DATA_path, 'roi_mask.nii' );
	CONFIG.dim              = [];
	CONFIG.pixdim           = [];
	CONFIG.OUTPUT_path      = [];

	CONFIG.schemeFilename	= fullfile( CONFIG.DATA_path, 'DWI.scheme' );
	CONFIG.scheme			= [];
    CONFIG.b0_thr           = 1;

	CONFIG.OPTIMIZATION     = [];

