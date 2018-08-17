classdef qsm_sb < AbstractModel
% CustomExample :  Quantitative susceptibility mapping
%
% Inputs:
%   PhaseGRe    3D xxx
%   (MagnGRE)     3D xxx
%   Mask        Binary mask
%
% Assumptions:
% (1)FILL
% (2)
%
% Fitted Parameters:
%    chi_SB
%    chi_L2
%
% Non-Fitted Parameters:
%    residue                    Fitting residue.
%
% Options:
%   Q-space regularization
%       Smooth q-space data per shell b code for the complete reconstruction pipeline (Laplacian unwrapping, SHARP filtering, ℓ2- and ℓ1- regularized fast susceptibility mapping with magnitude weighting and parameter estimation) is included as supplementary material and made available prior fitting
%
% Example of command line usage (see also <a href="matlab: showdemo Custom_batch">showdemo Custom_batch</a>):
%   For more examples: <a href="matlab: qMRusage(Custom);">qMRusage(Custom)</a>
%
% Authors: Mathieu Boudreau and Agah Karakuzu
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

% --- Fitted parameters
xnames = { 'chi_SB','chi_L2', 'mask_Sharp',...
'magn_weight'};

voxelwise = 0;

% Protocols linked to the OSF data
Prot = struct('Resolution',struct('Format',{{'VoxDim[1] (mm)' 'VoxDim[2] (mm)' 'VoxDim[3] (mm)'}},...
'Mat',  [0.6 0.6 0.6]),...
'Timing',struct('Format',{{'TE (s)'}},...
'Mat', 8.1e-3), ...
'Magnetization', struct('Format', {{'Field Strength (T)' 'Central Freq. (MHz)'}}, 'Mat', [3 42.58]));


% Model options
buttons = {'Direction',{'forward','backward'}, 'Sharp Filtering', true, 'Sharp Mode', {'once','iterative'}, 'Padding Size', [9 9 9],'Magnitude Weighting',false,'PANEL', 'Regularization Selection', 4,...
'L1 Regularized', false, 'L2 Regularized', false, 'Split-Bregman', false, 'No Regularization', false, ...
'PANEL', 'L1 Panel',2, 'Lambda L1', 5, 'ReOptimize Lambda L1', false, 'L1 Range', [-4 2.5 15], ...
'PANEL', 'L2 Panel', 2, 'Lambda L2',5, 'ReOptimize Lambda L2', false, 'L2 Range', [-4 2.5 15]
};

% Tiptool descriptions
tips = {'Direction','Direction of the differentiation', ...
'Magnitude Weighting', 'Calculates gradient masks from Magn data using k-space gradients and includes magn weighting in susceptibility maping.',...
'Sharp Filtering', 'Enable/Disable SHARP background removal.', ...
'Sharp Mode', 'Once: 9x9x9 kernel. Iterative: 9x9x9 to 3x3x3 with the step size of -2x-2x-2.', ...
'Padding Size', 'Zero padding size for SHARP kernel convolutions.', ...
'L1 Regularized', 'Open L1 regulatization panel.', ...
'L2 Regularized', 'Open L2 regulatization panel.', ...
'Split-Bregman',  'Perform Split-Bregman quantitative susceptibility mapping.', ...
'ReOptimize Lambda L1', 'Do not use default or user-defined Lambda L1.', ...
'ReOptimize Lambda L2', 'Do not use default or user-defined Lambda L2.', ...
'L1 Range','L1 regularization weights for optimization [min max N]',...
'L2 Range','L2 regularization weights for optimization [min max N]'
};

options= struct();

end % Public properties

properties (Hidden = true)

lambdaL1Range = [];
lambdaL2Range = [];

onlineData_url = 'https://osf.io/rn572/download/';

end % Hidden public properties

methods

function obj = qsm_sb


  % Transfer regularization parameter optimization range to the logspace
  obj.lambdaL1Range = logspace(obj.rangeL1(1),obj.rangeL1(2), obj.rangeL1(3));
  obj.lambdaL2Range = logspace(obj.rangeL2(1), obj.rangeL2(2), obj.rangeL2(3));
  % Convert buttons to options
  obj.options = button2opts(obj.buttons);
  % UpdateFields to take GUI interactions their effect on opening.
  obj = UpdateFields(obj);

end % fx: Constructor

function obj = UpdateFields(obj)

  % Functional but imperfect for now. When Split-Bergman
  % selected,you cannot disable L1 and L2, but they are not
  % disabled. Use state = getCheckBoxState(obj,checkBoxName)
  % later.

  obj = linkGUIState(obj, 'Sharp Filtering', 'Sharp Mode', 'show_hide_button', 'active_1');
  obj = linkGUIState(obj, 'Sharp Filtering', 'Padding Size', 'show_hide_button', 'active_1');

  obj = linkGUIState(obj, 'Split-Bregman', 'L1 Regularized', 'enable_disable_button', 'active_0', true);
  obj = linkGUIState(obj, 'No Regularization', 'L1 Regularized', 'enable_disable_button', 'active_0',false);

  obj = linkGUIState(obj, 'Split-Bregman', 'L2 Regularized', 'enable_disable_button', 'active_0', true);
  obj = linkGUIState(obj, 'No Regularization', 'L2 Regularized', 'enable_disable_button', 'active_0',false);

  obj = linkGUIState(obj, 'No Regularization', 'Split-Bregman', 'enable_disable_button', 'active_0',false);
  obj = linkGUIState(obj, 'Split-Bregman', 'No Regularization', 'enable_disable_button', 'active_0',false);

  obj = linkGUIState(obj, 'L1 Regularized', 'L1 Panel', 'show_hide_panel', 'active_1');
  obj = linkGUIState(obj, 'L2 Regularized', 'L2 Panel', 'show_hide_panel', 'active_1');

  obj = linkGUIState(obj, 'ReOptimize Lambda L1', 'L1 Range', 'show_hide_button', 'active_1');
  obj = linkGUIState(obj, 'ReOptimize Lambda L2', 'L2 Range', 'show_hide_button', 'active_1');
  obj = linkGUIState(obj, 'ReOptimize Lambda L1', 'Lambda L1', 'enable_disable_button', 'active_0');
  obj = linkGUIState(obj, 'ReOptimize Lambda L2', 'Lambda L2', 'enable_disable_button', 'active_0');

end %fx: UpdateFields (Member)

function FitResults = fit(obj,data)

  gyro =   2*pi*(obj.Prot.Magnetization.Mat(2));
  B0   =   obj.Prot.Magnetization.Mat(1);
  TE   =   obj.Prot.Timing.Mat;
  imageResolution = obj.Prot.Resolution.Mat;
  FitOpt = GetFitOpt(obj)

  % For now, assuming wrapped phase.

  % Mask wrapped phase
  data.Mask = logical(data.Mask);
  data.PhaseGRE(~data.Mask) = 0;

  if FitOpt.sharp_Flag % SHARP BG removal

    phaseWrapPad = padVolumeForSharp(data.PhaseGRE, FitOpt.padSize);
    maskPad      = padVolumeForSharp(data.Mask, FitOpt.padSize);

    disp('Started   : Laplacian phase unwrapping ...');
    phaseLUnwrap = unwrapPhaseLaplacian(phaseWrapPad);
    disp('Completed : Laplacian phase unwrapping');

    disp('Started   : SHARP background removal ...');
    [nfmSharpLUnwrap, maskSharp] = backgroundRemovalSharp(phaseLUnwrap, maskPad, [TE B0 gyro], FitOpt.sharpMode);
    disp('Completed : SHARP background removal');

  else

    disp('Started   : Laplacian phase unwrapping ...');
    phaseLUnwrap = unwrapPhaseLaplacian(data.PhaseGRE);
    disp('Completed : Laplacian phase unwrapping');

  end % SHARP BG removal

  if not(isempty(data.MagnGRE)) && FitOpt.magnW_Flag % Magnitude weighting

    if FitOpt.sharp_Flag

      disp('Started   : Calculation of gradient masks for magn weighting ...');
      magnWeight = calcGradientMaskFromMagnitudeImage(data.MagnGRE, maskSharp, padSize, FitOpt.direction)
      disp('Completed : Calculation of gradient masks for magn weighting');

    else

      % NOT SURE AT ALL IF THIS IS LEGIT

      disp('Started   : Calculation of gradient masks for magn weighting ...');
      magnWeight = calcGradientMaskFromMagnitudeImage(data.MagnGRE, data.Mask, [0 0 0], FitOpt.direction)
      disp('Completed : Calculation of gradient masks for magn weighting');

    end

  elseif isempty(data.MagnGRE) && FitOpt.magnW_Flag

    error('Magnitude data is missing. Cannot perform weighting.');

  end % Magnitude weighting

% Lambda one has a dependency on Lambda2. On the other hand, there is no
% chi_L1.

% HERE YOU LEFT -------------------------------------------------------> 
if FitOpt.regL2_Flag
[ lambda_L2, chi_L2 ] = calcLambdaL2(nfm_Sharp_lunwrap, mask_sharp, lambdaL2Range, imageResolution, directionFlag, pad_size);

else

lambdaL2 = FitOpt.

end

  % Some functions are added as nasted functions for memory management.
  % --------------------------------------------------------------------

  function paddedVolume = padVolumeForSharp(inputVolume, padSize)
    % Pads mask and wrapped phase volumes with zeros for SHARP convolutions.

    paddedVolume = padarray(inputVolume, padSize);

  end % fx: padVolumeForSharp (Nested)

  function [fdx, fdy, fdz] = calcFdr(N, direction)
    % N: Size of the volumes
    % direction: Direction of the differentiation.

    [k2,k1,k3] = meshgrid(0:N(2)-1, 0:N(1)-1, 0:N(3)-1);

    switch direction
    case 'forward'
      fdx = 1 - exp(-2*pi*1i*k1/N(1));
      fdy = 1 - exp(-2*pi*1i*k2/N(2));
      fdz = 1 - exp(-2*pi*1i*k3/N(3));
    case 'backward'
      fdx = -1 + exp(2*pi*1i*k1/N(1));
      fdy = -1 + exp(2*pi*1i*k2/N(2));
      fdz = -1 + exp(2*pi*1i*k3/N(3));
    end

  end % fx: calcFdr (Nested)

  function magnWeight = calcGradientMaskFromMagnitudeImage(magnVolume, maskSharp, padSize, direction)
    % Calculates gradient masks from magnitude image using k-space gradients.

    N = size(maskSharp);

    [fdx, fdy, fdz] = calcFdr(N, direction);

    magnPad = padarray(magnVolume, padSize) .* maskSharp;
    magnPad = magnPad / max(magnPad(:));

    Magn = fftn(magnPad);
    magnGrad = cat(4, ifftn(Magn.*fdx), ifftn(Magn.*fdy), ifftn(Magn.*fdz));

    magnWeight = zeros(size(magnGrad));

    for s = 1:size(magn_grad,4)

      magnUse = abs(magnGrad(:,:,:,s));

      magnOrder = sort(magnUse(maskSharp==1), 'descend');
      magnThreshold = magnOrder( round(length(magnOrder) * .3) );
      magnWeight(:,:,:,s) = magnUse <= magnThreshold;

    end

  end % calcGradientMaskFromMagnitudeImage (Nested)

  % --------------------------------------------------------------------

end % fx: fit (Member)


function FitOpt = GetFitOpt(obj)

  FitOpt.padSize = obj.options.PaddingSize;
  FitOpt.direction = obj.options.Direction;
  FitOpt.sharp_Flag = obj.options.SharpFiltering;
  FitOpt.sharpMode = obj.options.SharpMode;

  FitOpt.regSB_Flag = obj.options.RegularizationSelection_SplitBregman;
  FitOpt.regL1_Flag = obj.options.RegularizationSelection_L1Regularized;
  FitOpt.regL2_Flag = obj.options.RegularizationSelection_L2Regularized;
  FitOpt.noreg_Flag = obj.options.RegularizationSelection_NoRegularization;

  FitOpt.magnW_Flag = obj.options.MagnitudeWeighting;

  FitOpt.LambdaL1 = obj.options.L1Panel_LambdaL1;
  FitOpt.LambdaL2 = obj.options.L2Panel_LambdaL2;

  FitOpt.lambdaL1Range = obj.lambdaL1Range;
  FitOpt.lambdaL2Range = obj.lambdaL2Range;

end % fx: GetFitOpt (member)


end

end
