classdef qsm_sb < AbstractModel
% qsm_sb: Fast quantitative susceptibility mapping
%
% Assumptions:
% Type/number of outputs will depend on the selected options. 
% (1) Case - Split-Bregman:
%       i)  W/ magnitude weighting:  chiSBM, chiL2M, chiL2, unwrappedPhase, maskOut
%       ii) W/O magnitude weighting: chiSM, chiL2, unwrappedPhase, maskOut
%
% (2) Case - L2 Regularization:
%       i)  W/ magnitude weighting:  chiL2M, chiL2, unwrappedPhase, maskOut
%       ii) W/O magnitude weighting: chiL2, unwrappedPhase, maskOut
%
% (3) Case - No Regularization: 
%       i) Magnitude weighting is not enabled: nfm, unwrappedPhase, maskOut
% Inputs:
%   PhaseGRE        3D GRE acquisition. |Wrapped phase image|
%   (MagnGRE)       3D GRE acquisition. |Magnitude part of the image| (OPTIONAL)
%   Mask            Brain extraction mask.
%
% Outputs:
%   chiSBM          Susceptibility map created using Split-Bregman method with 
%                   magnitude weighting
%
%   chiSB           Susceptibility map created using Split-Bregman method without
%                   magnitude weighting.
%
%   chiL2M          Susceptibility map created using L2 regularization with 
%                   magnitude weighting
%
%   chiL2           Susceptibility map created using L2 regularization without 
%                   magnitude weighting
%
%   nfm             Susceptibility map created without regularization
%   unwrappedPhase  Unwrapped phase image using Laplacian-based method
%   maskOut         Binary mask (maskSharp, gradientMask or same as the input)
%
% Options:
%   Derivative direction               Direction of the derivation 
%                                        - forward 
%                                        - backward
%
%   SHARP Filtering                    Sophisticated harmonic artifact reduction for phase data
%                                        - State: true/false
%                                        - Mode: once/iterative 
%                                        - Padding Size: [1X3 array]
%                                        - Magnitude Weighting: on/off
%
%   L1-Regularization                  Apply L1-regularization 
%                                        - State: true/false
%                                        - Reoptimize parameters:
%                                        true/false
%                                        - Lambda-L1: [double]
%                                        - L1-Range:  [1X2 array]
%
%   L2-Regularization                  Apply L2-regularization 
%                                        - State: true/false
%                                        - Reoptimize parameters:
%                                        true/false
%                                        - Lambda-L2: [double]
%                                        - L2-Range:  [1X2 array]
%
%   Split-Bregman                       Apply Split-Bregman method 
%                                        - State: true/false
%                                        - Reoptimize parameters:
%
% Authors: Agah Karakuzu, 2018
%
% References:
%   Please cite the following if you use this module:
%     Bilgic et al. (2014), Fast quantitative susceptibility mapping with
%     L1-regularization and automatic parameter selection. Magn. Reson. Med.,
%     72: 1444-1459. doi:10.1002/mrm.25029
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343


properties

% --- Inputs
MRIinputs = {'PhaseGRE', 'MagnGRE', 'Mask'};

% --- Fitted parameters (please see the header for details)
xnames = { 'chiSB','chiL2', 'unwrappedPhase','maskOut' };

voxelwise = 0;

% Protocols linked to the OSF data
Prot = struct('Resolution',struct('Format',{{'xDim (mm)' 'yDim (mm)' 'zDim (mm)'}},...
'Mat',  [0.6 0.6 0.6]),...
'Timing',struct('Format',{{'TE (s)'}},...
'Mat', 8.1e-3), ...
'Magnetization', struct('Format', {{'FieldStrength (T)' 'CentralFreq (MHz)'}}, 'Mat', [3 42.58]));


% Model options
buttons = {'Derivative Direction',{'forward','backward'}, 'Sharp Filtering', true, 'Sharp Mode', {'once','iterative'}, 'Padding Size', [9 9 9],'Magnitude Weighting',false,'PANEL', 'Regularization Selection', 4,...
'Split-Bregman', true,'L1 Regularized', false, 'L2 Regularized', false, 'No Regularization', false, ...
'PANEL', 'L1 Panel',3, 'Lambda L1', 9.210553177e-04, 'ReOptimize Lambda L1', false, 'L1 Range', [-4 -2.5 15], ...
'PANEL', 'L2 Panel', 3, 'Lambda L2',0.0316228, 'ReOptimize Lambda L2', false, 'L2 Range', [-3 0 15]
};

% Tiptool descriptions
tips = {'Derivative Direction','Direction of the differentiation. Global to the calculations of grad. mask, lambda L1 & L2 and chi maps.', ...
'Magnitude Weighting', 'Calculates gradient masks from Magn data using k-space gradients and includes magn weighting in susceptibility maping.',...
'Sharp Filtering', 'Enable/Disable SHARP background removal.', ...
'Sharp Mode', 'Once: 9x9x9 kernel. Iterative: From 9x9x9 to 3x3x3 with the step size of -2x-2x-2.', ...
'Padding Size', 'Zero padding size for SHARP kernel convolutions.', ...
'L1 Regularized', 'Open L1 regulatization panel.', ...
'L2 Regularized', 'Open L2 regulatization panel.', ...
'Split-Bregman',  'Perform Split-Bregman quantitative susceptibility mapping.', ...
'ReOptimize Lambda L1', 'Do not use default or user-defined Lambda L1.', ...
'ReOptimize Lambda L2', 'Do not use default or user-defined Lambda L2.', ...
'L1 Range','Optimization range for L1 regularization weights [min max N]',...
'L2 Range','Optimization range for L2 regularization weights [min max N]'
};

options= struct();

end % Public properties

properties (Hidden = true)
% See the constructor.
onlineData_url;

end % Hidden public properties

methods

function obj = qsm_sb


  % Convert buttons to options
  obj.options = button2opts(obj.buttons);
  % UpdateFields to take GUI interactions their effect on opening.
  obj = UpdateFields(obj);
  obj.onlineData_url = obj.getLink('https://osf.io/9d8kz/download?version=1','https://osf.io/549ke/download?version=4','https://osf.io/549ke/download?version=4');

end % fx: Constructor

function obj = UpdateFields(obj)

  obj = linkGUIState(obj, 'Sharp Filtering', 'Sharp Mode', 'show_hide_button', 'active_1');
  obj = linkGUIState(obj, 'Sharp Filtering', 'Padding Size', 'show_hide_button', 'active_1');

  obj = linkGUIState(obj, 'Split-Bregman', 'L1 Regularized', 'enable_disable_button', 'active_0', true);
  obj = linkGUIState(obj, 'No Regularization', 'L1 Regularized', 'enable_disable_button', 'active_0',false);

  obj = linkGUIState(obj, 'Split-Bregman', 'L2 Regularized', 'enable_disable_button', 'active_0', true);
  obj = linkGUIState(obj, 'No Regularization', 'L2 Regularized', 'enable_disable_button', 'active_0',false);

  obj = linkGUIState(obj, 'No Regularization', 'Split-Bregman', 'enable_disable_button', 'active_0',false);
  obj = linkGUIState(obj, 'Split-Bregman', 'No Regularization', 'enable_disable_button', 'active_0',false);

  obj = linkGUIState(obj, 'No Regularization', 'Magnitude Weighting', 'enable_disable_button', 'active_0',false);

  obj = linkGUIState(obj, 'L1 Regularized', 'L1 Panel', 'show_hide_panel', 'active_1');
  obj = linkGUIState(obj, 'L2 Regularized', 'L2 Panel', 'show_hide_panel', 'active_1');

  obj = linkGUIState(obj, 'ReOptimize Lambda L1', 'L1 Range', 'show_hide_button', 'active_1');
  obj = linkGUIState(obj, 'ReOptimize Lambda L2', 'L2 Range', 'show_hide_button', 'active_1');
  obj = linkGUIState(obj, 'ReOptimize Lambda L1', 'Lambda L1', 'enable_disable_button', 'active_0');
  obj = linkGUIState(obj, 'ReOptimize Lambda L2', 'Lambda L2', 'enable_disable_button', 'active_0');

  if not(getCheckBoxState(obj,'L2 Regularized')) && not(getCheckBoxState(obj,'No Regularization')) && not(getCheckBoxState(obj,'Split-Bregman')) || ...
    getCheckBoxState(obj,'L2 Regularized') && not(getCheckBoxState(obj,'No Regularization')) && not(getCheckBoxState(obj,'Split-Bregman'))

    obj.options.RegularizationSelection_L1Regularized = false;
    obj = setPanelInvisible(obj,'L1 Panel', 1);
    obj = setButtonDisabled(obj,'L1 Regularized', 1);
  end

  if getCheckBoxState(obj,'L2 Regularized') && getCheckBoxState(obj,'L1 Regularized') && getCheckBoxState(obj,'Split-Bregman')

    obj = setButtonDisabled(obj,'L1 Regularized', 1);
    obj = setButtonDisabled(obj,'L2 Regularized', 1);

  end

  if not(getCheckBoxState(obj,'L2 Regularized'))

    obj = setPanelInvisible(obj,'L2 Panel', 1);

  end

  if not(getCheckBoxState(obj,'L1 Regularized'))

    obj = setPanelInvisible(obj,'L1 Panel', 1);

  end

end %fx: UpdateFields (Member)

function FitResults = fit(obj,data)

  gyro =   2*pi*(obj.Prot.Magnetization.Mat(2));
  B0   =   obj.Prot.Magnetization.Mat(1);
  TE   =   obj.Prot.Timing.Mat;
  imageResolution = obj.Prot.Resolution.Mat;
  FitOpt = GetFitOpt(obj);
  FitResults = struct();

  %  DEV Note:
  %  Assuming wrapped phase.

  data.Mask = logical(data.Mask);
  data.PhaseGRE(~data.Mask) = 0;


  if not(FitOpt.noreg_Flag) && not(FitOpt.regL2_Flag) && not(FitOpt.regSB_Flag)

    errordlg('Please make a regularization selection.');
    error('Operation has exited.')

  end

  % DEV Note:
  % No data change with these once they are assigned. Therefore setting
  % them persistent. Performance tests to be performed.

  persistent phaseLUnwrap maskGlobal

  % Pad data for SHARP (this is done before phase unwrapping only for
  % reproducibility's sake).
  if FitOpt.sharp_Flag
      padSize = FitOpt.padSize;
      data.PhaseGRE = padVolumeForSharp(data.PhaseGRE, padSize);
      maskPad = padVolumeForSharp(data.Mask, padSize);
      magnGREPad = padVolumeForSharp(data.MagnGRE, padSize);
  else
      padSize = [0,0,0];
      magnGREPad = data.MagnGRE;
  end
  
  % Estimate frequency from phase data
  nEcho = numel(TE);
  assert(nEcho == size(data.PhaseGRE,4));  
  
  if nEcho > 1 && not(isempty(data.MagnGRE))
      freqEstimate = averageEchoesWithWeights(data.PhaseGRE, magnGREPad, TE);
      clear magnGREPad % Release
  else
      disp('Started   : Laplacian phase unwrapping ...');
      for iEcho = nEcho:-1:1
          freqEstimate(:,:,:,iEcho) = unwrapPhaseLaplacian(data.PhaseGRE(:,:,:,iEcho));
      end
      disp('Completed : Laplacian phase unwrapping');
      disp('-----------------------------------------------');
      freqEstimate = mean(freqEstimate ./ reshape(TE, [1,1,1,numel(TE)]), 4);
  end
  data.phaseGRE = []; % Release
  
  % Scale frequency to ppm
  freqEstimatePpm = freqEstimate / (B0 * gyro);
  
  % SHARP BG removal
  if FitOpt.sharp_Flag
    disp('Started   : SHARP background removal ...');
    [phaseLUnwrap, maskGlobal] = backgroundRemovalSharp(freqEstimatePpm, maskPad, FitOpt.sharpMode);
    disp('Completed : SHARP background removal');
    disp('-----------------------------------------------');

    clear('freqEstimatePadPpm','maskPad')
    data.Mask = []; % Release
  else
      % DEV Note:
      % I assumed that even w/o SHARP, magn weight is possible by passing
      % brainmask and padding size as 0 0 0.
      
      % If there is sharp, phaseLUnwrap is the SHARP masked one
      % If there is not sharp phaseLUnwrap is just laplacian unwrapped phase.
      phaseLUnwrap = freqEstimatePpm;
      maskGlobal = data.Mask;
      data.Mask = [];
  end % SHARP BG removal

  if not(isempty(data.MagnGRE)) && FitOpt.magnW_Flag % Magnitude weighting

    if nEcho > 1
        data.MagnGRE = sqrt(sum(data.MagnGRE.^2, 4));
    end
    disp('Started   : Calculation of gradient masks for magn weighting ...');
    magnWeight = calcGradientMaskFromMagnitudeImage(data.MagnGRE, maskGlobal, padSize, FitOpt.direction);
    disp('Completed : Calculation of gradient masks for magn weighting');
    disp('-----------------------------------------------');

  elseif isempty(data.MagnGRE) && FitOpt.magnW_Flag

    error('Magnitude data is missing. Cannot perform weighting.');

  end % Magnitude weighting


  data.MagnGRE = [];

  if FitOpt.regL2_Flag && FitOpt.reoptL2_Flag  % || Reopt Lamda L2 case chi_L2 generation

    disp('Started   : Reoptimization of lamdaL2. ...');
    lambdaL2 = calcLambdaL2(phaseLUnwrap, FitOpt.lambdaL2Range, imageResolution, FitOpt.direction);

    if isempty(lambdaL2)

      warning('Could not optimize lambda L2 with provided search interval. Setting default value instead.');

      if not(isempty(FitOpt.LambdaL2))

        lambdaL2 = FitOpt.LambdaL2;

      else

        error('Cannot set lambda L2. Please enter a value or change range.')

      end
    end

    disp(['Completed   : Reoptimization of lamdaL2. Lambda L2: ' num2str(lambdaL2)]);
    disp('-----------------------------------------------');

    if  FitOpt.magnW_Flag % MagnitudeWeighting case | Lambdal2 reopted

      disp('Started   : Calculation of chi_L2 map with magnitude weighting...');
      [FitResults.chiL2,FitResults.chiL2M] = calcChiL2(phaseLUnwrap, lambdaL2, FitOpt.direction, imageResolution, maskGlobal, padSize, magnWeight);
      disp('Completed   : Calculation of chi_L2 map with magnitude weighting.');
      disp('-----------------------------------------------');

    else % No magnitude weighting case | Lambdal2 reopted

      disp('Started   : Calculation of chi_L2 map without magnitude weighting...');
      [FitResults.chiL2] = calcChiL2(phaseLUnwrap, lambdaL2, FitOpt.direction, imageResolution, maskGlobal, padSize);
      disp('Completed  : Calculation of chi_L2 map without magnitude weighting.');
      disp('-----------------------------------------------');
    end

  elseif FitOpt.regL2_Flag && not(FitOpt.reoptL2_Flag ) % || DO NOT reopt Lambda L2 case chi_L2 generation

    if isempty(FitOpt.LambdaL2) % In case user forgets

      error('Lambda2 value is needed. Please select Re-opt LambdaL2 if you dont know the value');

    else

      disp('Skipping reoptimization of Lambda L2.');
      lambdaL2 = FitOpt.LambdaL2;

    end

    if FitOpt.magnW_Flag % MagnitudeWeighting is present | Lambdal2 known

      disp('Started   : Calculation of chi_L2 map with magnitude weighting...');
      [FitResults.chiL2,FitResults.chiL2M] = calcChiL2(phaseLUnwrap, lambdaL2, FitOpt.direction, imageResolution, maskGlobal, padSize, magnWeight);
      disp('Completed   : Calculation of chi_L2 map with magnitude weighting.');
      disp('-----------------------------------------------');

    else % magn weight is not present | Lambdal2 known

      disp('Started   : Calculation of chi_L2 map without magnitude weighting...');
      [FitResults.chiL2] = calcChiL2(phaseLUnwrap, lambdaL2, FitOpt.direction, imageResolution, maskGlobal, padSize);
      disp('Completed  : Calculation of chi_L2 map without magnitude weighting.');
      disp('-----------------------------------------------');

    end

  end

  % DEV note:
  % L1 flag is raised only if split bregman is selected

  if FitOpt.regL1_Flag && FitOpt.reoptL1_Flag  % || Reopt Lamda L2 case chi_L2 generation

    disp('Started   : Reoptimization of Lamda L1. ...');
    lambdaL1 = calcSBLambdaL1(phaseLUnwrap, FitOpt.lambdaL1Range, lambdaL2, imageResolution, FitOpt.direction);
    disp('Completed   : Reoptimization of Lamda L1. ...');
    disp(['Completed   : Reoptimization of lamda L1. Lambda L1: ' num2str(lambdaL1)]);
    disp('-----------------------------------------------');

    if isempty(lambdaL1)

      warning('Could not optimize lambda L1 with provided search interval. Setting default value instead.');

      if not(isempty(FitOpt.LambdaL1))

        lambdaL1 = FitOpt.LambdaL1;

      else

        error('Cannot set lambda L1. Please enter a value or change range.')

      end
    end

  elseif FitOpt.regL1_Flag && not(FitOpt.reoptL1_Flag)

    lambdaL1 = FitOpt.LambdaL1;

  end


  if FitOpt.regSB_Flag && FitOpt.magnW_Flag

    disp('Started   : Calculation of chi_SB map with magnitude weighting.. ...');
    FitResults.chiSBM = qsmSplitBregman(phaseLUnwrap, maskGlobal, lambdaL1, lambdaL2, FitOpt.direction, imageResolution, padSize, FitOpt.magnW_Flag, magnWeight);
    disp('Completed   : Calculation of chi_SB map with magnitude weighting.');
    disp('-----------------------------------------------');

  elseif FitOpt.regSB_Flag && not(FitOpt.magnW_Flag)

    disp('Started   : Calculation of chi_SB map without magnitude weighting.. ...');
    FitResults.chiSB = qsmSplitBregman(phaseLUnwrap, maskGlobal, lambdaL1, lambdaL2, FitOpt.direction, imageResolution, padSize);
    disp('Completed   : Calculation of chi_SB map without magnitude weighting.');
    disp('-----------------------------------------------');

  end
  
  if FitOpt.noreg_Flag

    FitResults.nfm = abs(phaseLUnwrap(1+padSize(1):end-padSize(1),1+padSize(2):end-padSize(2),1+padSize(3):end-padSize(3)));

  end



  if not(isdeployed) && not(exist('OCTAVE_VERSION', 'builtin'))
    disp('Loading outputs to the GUI may take some time after fit has been completed.');
  end

  % --------------------------------------------------------------------
  FitResults.unwrappedPhase = phaseLUnwrap;

  if exist('magnWeight') == 1
    FitResults.maskOut = double(magnWeight);
  else
    FitResults.maskOut = double(maskGlobal);
  end

  if isfield(FitResults, 'chiSBM')
    FitResults = orderfields(FitResults, {'chiSBM','chiL2M','chiL2','unwrappedPhase','maskOut'});
  end

  if isfield(FitResults, 'chiSB')
    FitResults = orderfields(FitResults, {'chiSB','chiL2','unwrappedPhase','maskOut'});
  end

end % fx: fit (Member)


function FitOpt = GetFitOpt(obj)

  FitOpt.padSize = obj.options.PaddingSize;
  FitOpt.direction = obj.options.DerivativeDirection;
  FitOpt.sharp_Flag = obj.options.SharpFiltering;
  FitOpt.sharpMode = obj.options.SharpMode;

  FitOpt.regSB_Flag = obj.options.RegularizationSelection_SplitBregman;
  FitOpt.regL1_Flag = obj.options.RegularizationSelection_L1Regularized;
  FitOpt.regL2_Flag = obj.options.RegularizationSelection_L2Regularized;
  FitOpt.noreg_Flag = obj.options.RegularizationSelection_NoRegularization;

  FitOpt.magnW_Flag = obj.options.MagnitudeWeighting;

  FitOpt.LambdaL1 = obj.options.L1Panel_LambdaL1;
  FitOpt.LambdaL2 = obj.options.L2Panel_LambdaL2;

  FitOpt.reoptL1_Flag = obj.options.L1Panel_ReOptimizeLambdaL1;
  FitOpt.reoptL2_Flag = obj.options.L2Panel_ReOptimizeLambdaL2;

  l1r = obj.options.L1Panel_L1Range;
  l2r = obj.options.L2Panel_L2Range;

  FitOpt.lambdaL1Range = logspace(l1r(1),l1r(2),l1r(3));
  FitOpt.lambdaL2Range = logspace(l2r(1),l2r(2),l2r(3));

end % fx: GetFitOpt (member)


end


    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            % 2.0.10
            if checkanteriorver(version,[2 0 10])
                % Update buttons for joker conversion from ###/*** to ##/**
                obj.buttons = cellfun(@(x) strrep(x,'###','##'),obj.buttons,'uni',0);
                obj.buttons = cellfun(@(x) strrep(x,'***','**'),obj.buttons,'uni',0);
            end
        end
    end

end
