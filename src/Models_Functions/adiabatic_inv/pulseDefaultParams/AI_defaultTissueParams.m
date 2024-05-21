%% Sort based on field strength and tissue type
function Params = AI_defaultTissueParams(Params)
% currently only 3T and 7T are supported fields;
% currently only 'GM' and 'WM' are the supported tissue types.

% 3T parameters taken from:
% Sled, J.G., Pike, B.G., 2001. Quantitative imaging of magnetization transfer exchange and relaxation properties in vivo using MRI. Magn. Reson. Med. 46, 923–931. https://doi.org/10.1002/mrm.1278


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%  3T %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
if Params.B0 == 3

    if strcmp(Params.TissueType, 'GM')
        Params.M0a = 1;
        Params.Raobs = 1/1.4; 
        Params.R = 50; % 
        Params.T2a = 50e-3; % Sled and Pike 2001
        Params.T1D = 7.5e-4; % Varma 2017 was 6ms
        Params.lineshape = 'SuperLorentzian'; % or 'SuperLorentzian';
        Params.R1b = 0.25;
        Params.T2b = 11.5e-6; 
        Params.Ra = [];
        Params.M0b =  0.071;
        Params.D = 0.8e-3/1e6; % diffusion coefficient-> convert from mm^2/s to m^2/s

    elseif strcmp(Params.TissueType, 'WM')
        Params.M0a = 1;
        Params.Raobs = 1/0.85; 
        Params.R = 35;
        Params.T2a = 35e-3; % Sled and Pike 2001
        Params.T1D = 1.25e-3; % Varma 2017 was 6ms
        Params.lineshape = 'SuperLorentzian'; % or 'SuperLorentzian';
        Params.R1b = 0.25;
        Params.T2b = 11.1e-6;
        Params.Ra = [];
        Params.M0b =  0.155;
        Params.D = 1e-3/1e6; % diffusion coefficient-> convert from mm^2/s to m^2/s

    else
        error('Please set Params.TissueType to either GM or WM, or build an additional field')
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%  7T %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
elseif Params.B0 == 7

    if strcmp(Params.TissueType, 'GM')
        Params.M0a = 1;
        Params.Raobs = 1/2; 
        Params.R = 33; % 
        Params.T2a = 45e-3; 
        Params.T1D = 5.25e-4; % Varma 2017 was 6ms
        Params.lineshape = 'SuperLorentzian'; % or 'SuperLorentzian';
        Params.R1b = 0.25;
        Params.T2b = 11e-6; 
        Params.Ra = [];
        Params.M0b =  0.075;
        Params.D = 0.8e-3/1e6; % diffusion coefficient-> convert from mm^2/s to m^2/s

    elseif strcmp(Params.TissueType, 'WM')
        Params.M0a = 1;
        Params.Raobs = 1/1.4; 
        Params.R = 27;
        Params.T2a = 45e-3; 
        Params.T1D = 5.25e-4; % Varma 2017 was 6ms
        Params.lineshape = 'SuperLorentzian'; % or 'SuperLorentzian';
        Params.R1b = 0.25;
        Params.T2b = 11.1e-6;
        Params.Ra = [];
        Params.M0b =  0.155;
        Params.D = 1e-3/1e6; % diffusion coefficient-> convert from mm^2/s to m^2/s

    else
        error('Please set Params.TissueType to either GM or WM, or build an additional field')
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%% 1.5T %%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Use the optimizations from: Levesque, I.R., Sled, J.G., Pike, G.B., 2011. 
% Iterative optimization method for design of quantitative magnetization transfer 
% imaging experiments. Magn. Reson. Med. 66, 635–643. https://doi.org/10.1002/mrm.23071
elseif Params.B0 == 1.5

    if strcmp(Params.TissueType, 'GM')
        Params.M0a = 1;
        Params.Raobs = 1/2; 
        Params.R = 25.7; % 
        Params.T2a = 51e-3; 
        Params.T1D = 5.25e-4; % Varma 2017 was 6ms
        Params.lineshape = 'SuperLorentzian'; % or 'SuperLorentzian';
        Params.R1b = 0.25;
        Params.T2b = 11e-6; 
        Params.Ra = 1;
        Params.M0b =  0.07;
        Params.D = 0.8e-3/1e6; % diffusion coefficient-> convert from mm^2/s to m^2/s

    elseif strcmp(Params.TissueType, 'WM')
        Params.M0a = 1;
        Params.Raobs = 1/0.55; 
        Params.R = 25;
        Params.T2a = 35e-3; 
        Params.T1D = 5.25e-4; % Varma 2017 was 6ms
        Params.lineshape = 'SuperLorentzian'; % or 'SuperLorentzian';
        Params.R1b = 0.25;
        Params.T2b = 12e-6;
        Params.Ra = 1.8;
        Params.M0b =  0.16;
        Params.D = 1e-3/1e6; % diffusion coefficient-> convert from mm^2/s to m^2/s

    else
        error('Please set Params.TissueType to either GM or WM, or build an additional field')
    end

else
    error('Please set Params.B0 to either 3,7, or build an additional field')
end


if isempty(Params.Ra) % allow you to specify either Ra or Raobs
    Params.Ra = Params.Raobs - ((Params.R * Params.M0b * (Params.R1b - Params.Raobs)) / (Params.R1b - Params.Raobs + Params.R));
    if isnan(Params.Ra)
        Params.Ra = 1;
    end
end

