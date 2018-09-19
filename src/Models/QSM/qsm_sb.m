classdef qsm_sb < AbstractModel
% qsm_sb :  Fast reconstruction quantitative susceptibility maps with total
% variation penalty and automatic regularization parameter selection.
%
% Inputs:
%   PhaseGRE    3D GRE acquisition. << Wrapped phase image. >>
%   (MagnGRE)   3D GRE acquisition. << Magnitude part of the image. >>
%   Mask        Brain extraction mask.
%
% Assumptions:
% (1)
% (2)
%
% Fitted Parameters:
%
%    Case - Split-Bregman:
%       i)  W/ magnitude weighting:  chiSBM, chiL2M, chiL2, unwrappedPhase, maskOut
%       ii) W/O magnitude weighting: chiSM, chiL2, unwrappedPhase, maskOut
%
%    Case - L2 Regularization:
%       i)  W/ magnitude weighting:  chiL2M, chiL2, unwrappedPhase, maskOut
%       ii) W/O magnitude weighting: chiL2, unwrappedPhase, maskOut
%
%    Case - No Regularization:
%       i) Magnitude weighting is not enabled: nfm, unwrappedPhase, maskOut
%
%    Explanation of all parameters:
%       chiSBM
%       chiSB
%       chiL2M
%       chiL2
%       nfm
%       unwrappedPhase
%       maskOut (maskSharp, gradientMask or same as the input)
%
%
% Options:
%   To be listed.
%
%
%
%
% Authors: Agah Karakuzu
%
% References:
%   Please cite the following if you use this module:
%
%     Bilgic et al. (2014), Fast quantitative susceptibility mapping with
%     L1-regularization and automatic parameter selection. Magn. Reson. Med.,
%     72: 1444-1459. doi:10.1002/mrm.25029
%
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

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
'PANEL', 'L1 Panel',2, 'Lambda L1', 9.210553177e-04, 'ReOptimize Lambda L1', false, 'L1 Range', [-4 -2.5 15], ...
'PANEL', 'L2 Panel', 2, 'Lambda L2',0.0316228, 'ReOptimize Lambda L2', false, 'L2 Range', [-3 0 15]
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

onlineData_url = getLink;

end % Hidden public properties

methods

function obj = qsm_sb


  % Convert buttons to options
  obj.options = button2opts(obj.buttons);
  % UpdateFields to take GUI interactions their effect on opening.
  obj = UpdateFields(obj);

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

  if FitOpt.sharp_Flag % SHARP BG removal

    padSize = FitOpt.padSize;

    phaseWrapPad = padVolumeForSharp(data.PhaseGRE, padSize);
    maskPad      = padVolumeForSharp(data.Mask, padSize);

    data.PhaseGRE = []; % Release

    disp('Started   : Laplacian phase unwrapping ...');
    phaseLUnwrap_tmp = unwrapPhaseLaplacian(phaseWrapPad);
    disp('Completed : Laplacian phase unwrapping');
    disp('-----------------------------------------------');

    clear('phaseWrapPad'); % Release

    disp('Started   : SHARP background removal ...');
    [phaseLUnwrap, maskGlobal] = backgroundRemovalSharp(phaseLUnwrap_tmp, maskPad, [TE B0 gyro], FitOpt.sharpMode);

    disp('Completed : SHARP background removal');
    disp('-----------------------------------------------');

    clear('phaseLUnwrap_tmp','maskPad')
    data.Mask = []; % Release


  else

    disp('Started   : Laplacian phase unwrapping ...');
    phaseLUnwrap = unwrapPhaseLaplacian(data.PhaseGRE);
    disp('Completed : Laplacian phase unwrapping');
    disp('-----------------------------------------------');

    data.phaseGRE = []; % Release

    % DEV Note:
    % I assumed that even w/o SHARP, magn weight is possible by passing
    % brainmask and padding size as 0 0 0.

    % If there is sharp, phaseLUnwrap is the SHARP masked one
    % If there is not sharp phaseLUnwrap is just laplacian unwrapped phase.

    maskGlobal = data.Mask;
    padSize    = [0 0 0];
    data.Mask = [];

  end % SHARP BG removal

  if not(isempty(data.MagnGRE)) && FitOpt.magnW_Flag % Magnitude weighting


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

  l1r = obj.options.L1Range;
  l2r = obj.options.L2Range;

  FitOpt.lambdaL1Range = logspace(l1r(1),l1r(2),l1r(3));
  FitOpt.lambdaL2Range = logspace(l2r(1),l2r(2),l2r(3));

end % fx: GetFitOpt (member)


end

end
