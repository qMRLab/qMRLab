function Sf = CacheSf(protocolArg,varargin)
%CACHESF qMRLab command line tool to calculate/cache the Sf table for a
%protocol.
%
%   protocolArg: 'struct' or 'char' 
%       case 'struct': Protocol structure variable (Prot).
%       case 'char': Path to the qMRLab protocol *.mat file. Sf is saved
%                    to the protocol file.
%
%   Example usage:
%       Prot.Sf = CacheSf(Prot);
%       CacheSf('/path/to/protFile.mat');
%
    
    %% Load protocol file
    %
    
    Prot = getProtocolStruct(protocolArg);
    
    %% Setup angles
    %

    angles = unique(Prot.Angles);
    SfAngles = zeros(length(angles)*3 +2,1);
    SfAngles(1) = 0;
    SfAngles(end) = max(angles)*1.5;
    minScale = 0.75;
    maxScale = 1.25;

    ind = 3;
    for i = 1:length(angles)
        SfAngles(ind) = angles(i);
        SfAngles(ind-1) = minScale*angles(i);
        SfAngles(ind+1) = maxScale*angles(i);
        ind = ind + 3;
    end
    SfAngles = unique(SfAngles);

    %% Setup offsets
    %
    
    % Extend offsets limits and add midpoints
    offsets = unique(Prot.Offsets);
    SfOffsets = zeros(length(offsets)*4 +2,1);
    SfOffsets(1) = 100;
    SfOffsets(end) = max(offsets) + 1000;
    maxOff = 100;
    offsets = [0; offsets];
    ind = 4;
    for i = 2:length(offsets)
        SfOffsets(ind-2) = 0.5*(offsets(i) + offsets(i-1));
        SfOffsets(ind-1) = offsets(i) - maxOff;
        SfOffsets(ind) = offsets(i);
        SfOffsets(ind+1) = offsets(i) + maxOff;
        ind = ind + 4;
    end
    SfOffsets = unique(SfOffsets);

    %% Setup T2f & pulse
    %
    
    % T2f = linspace(FitOpt.lb(5), FitOpt.ub(5), 20);
    T2f = [0.0010 0.0050 0.0100 0.0150 0.0200 0.0250 0.0300 0.0350 0.0400 ...
           0.0450 0.0500 0.0550 0.0600 0.0650 0.0700 0.0750 0.0800 0.0850 ...
           0.0900 0.2500 0.5000 1.0000];
    Trf = Prot.Tm;
    shape = Prot.MTpulse.shape;
    PulseOpt = Prot.MTpulse.opt;
    
    %% Compue Sf Cache
    %
    
    Sf = BuildSfTable(SfAngles, SfOffsets, T2f, Trf, shape, PulseOpt,varargin{:});

    %% If applicable (e.g. , Save protocol to 
    %

    if ischar(protocolArg) && ~isempty(Sf)
        Prot.Sf = Sf;
        
        % If protocolArg is a 'char', then it is the location of the saved
        % protocol variables.
        save(protocolArg, '-struct', 'Prot')
    end
end

%% Helper functions
%

function Prot = getProtocolStruct(protocolArg)
    protClass = class(protocolArg);
    
    switch protClass
        case 'struct'
            % For this case, protocolArg is expected to be the Prot struct
            % itself.
        	Prot = protocolArg;

        case 'char'
            % For this case, protocolArg is expected to be the path to a
            % saved protocol .mat file
        	Prot = load(protocolArg);
        otherwise
            error('qMRLab:CacheSf:unknownArgument', 'Input argument (protocolArg) is not of type ''struct'' or ''char''.');
    end

end
