function [T2, M0] = fit_T2meSE_monoexp(qData, EchoTimes, Opt , varargin)

%% Check input variables


ndef_inputs = 3;

ROI_flag = 0;
if nargin > ndef_inputs
    if strcmp(varargin{1},'ROI')
        Mask = varargin{2};
        ROI_flag = 1;
    end
end

if isempty(Opt)
    Opt = struct();
    Opt.voxelwise = 1;
    
    if length(EchoTimes) > 2
        Opt.fitMethod = 'LM'; 
        Opt.DropFirstEcho = true;
        Opt.OffsetTerm = true;
        Opt.cutoff = 3000;
    elseif length(EchoTimes) == 2
        Opt.fitMethod = 'LT'; 
        Opt.DropFirstEcho = [];
        Opt.OffsetTerm = [];
        Opt.cutoff = 3000;
    end
    
end

assignin('base','t2ops',Opt);


% Assumes that last dimension is the qDim

%% Vectorize input and save qMeta information

% Data and Mask dimension standardization block

if Opt.voxelwise == 1
    
    qMeta = struct();
    qMeta.datDim = size(qData);
    
    % datDim = [vDim X vDim X vDim] X [qDim]
    
    if ndims(qData) == 4  % 3D Volume
        
        qMeta.nvDim = 3;
        qMeta.numVox = qMeta.datDim(1)*qMeta.datDim(2)*qMeta.datDim(3);
        qMeta.numQnt = qMeta.datDim(4);
        
        
    elseif ndims(qData) == 3 % 2D Slice
        
        qMeta.nvDim = 2;
        qMeta.numVox = qMeta.datDim(1)*qMeta.datDim(2);
        qMeta.numQnt = qMeta.datDim(3);
        
    elseif ndims(qData) == 2 % Single voxel fit (ROA)
        
        qMeta.nvDim = 1;
        qMeta.numVox = qMeta.datDim(1);
        qMeta.numQnt = qMeta.datDim(2);
        
        
    end
    
    yData = reshape(qData,[qMeta.numVox qMeta.numQnt]);
    
    if ROI_flag
        maskVec = reshape(Mask,[qMeta.numVox,1]);
    end
    
end

%% Do fitting

if ROI_flag
    t2map = fit_t2(EchoTimes,yData,qMeta,Opt.fitMethod,'ROI',maskVec);
else
    t2map = fit_t2(EchoTimes,yData,qMeta,Opt.fitMethod);
end


%% Restore image from vector using qMeta

M0 = double(reshape(t2map(:,1),qMeta.datDim(1:qMeta.nvDim)));
T2 = double(reshape(t2map(:,2),qMeta.datDim(1:qMeta.nvDim)));


end


function [t2map] = fit_t2(xData,yData,qMeta,fitMethod,varargin)

ndef_inputs = 4;

ROI_flag = 0;
if nargin > ndef_inputs
    if strcmp(varargin{1},'ROI')
        maskVec = varargin{2}; % If ROI is passed, load mask as varg2
        ROI_flag = 1;
    end
end

if strcmp(fitMethod,'LM')
    nonlinFlag = true;
elseif strcmp(fitMethod,'LT')
    nonlinFlag = false;
end

t2map = zeros(qMeta.numVox,2);
warning('off');

for i=1:qMeta.numVox % Loop over all voxels
  
    if ROI_flag
        
        if maskVec(i) % Use maskvec here
            if nonlinFlag
                fit_out = t2LM(xData,yData(i,:)); % Fit with LM
            else
                fit_out = t2LT(xData,log(yData(i,:))); % Fit with LT
            end
            
            t2map(i,1) = fit_out(1);
            t2map(i,2) = fit_out(2);
            
        end
        
    else % If there is no mask
        
        if nonlinFlag
            fit_out = t2LM(xData,yData(i,:)); % Fit with LM
        else
            fit_out = t2LT(xData,log(yData(i,:))); % Fit with LT
        end
        
        t2map(i,1) = fit_out(1);
        t2map(i,2) = fit_out(2);
        
        
    end
    
end

warning('on');

end


function fit_out = t2LM(xData,yDat)
% Non-linear least squares using <<levenberg-marquardt (LM)>>

Opt = evalin('base','t2ops'); 

if Opt.DropFirstEcho
    yDat = yDat(2:end);
    xData = xData(2:end);
    
    if max(size(yDat)) == 1
        error('DropFirstEcho is not valid for ETL of 2.');
    end
    
end

xData = xData';

if Opt.OffsetTerm
    fT2 = @(a)(a(1)*exp(-xData/a(2)) + a(3)  - yDat);
else
    fT2 = @(a)(a(1)*exp(-xData/a(2)) - yDat);
end

yDat = abs(yDat);
yDat = yDat./max(yDat);


% T2 initialization adapted from
% https://github.com/blemasso/FLI_pipeline_T2/blob/master/matlab/pipeline_T2.m

t2Init_dif = xData(1) - xData(end-1);
t2Init = t2Init_dif/log(yDat(end-1)/yDat(1));

if t2Init<=0 || isnan(t2Init),
    t2Init=30;
end

pdInit = max(yDat(:))*1.5;

options.Algorithm = 'levenberg-marquardt';
options.Display = 'off';

if Opt.OffsetTerm
fit_out = lsqnonlin(fT2,[pdInit t2Init 0],[],[],options);
else
fit_out = lsqnonlin(fT2,[pdInit t2Init],[],[],options);
end


end


function fit_out  = t2LT(xData,yDatLog)
% Linearize solution with <<log transformation (LT)>>

Opt = evalin('base','t2ops'); 

regOut = [ones(size(xData)), xData] \ yDatLog';

fit_out(1) = exp(regOut(1));
if regOut(2) == 0 ; regOut(2) = eps; end;
t2 = -1./regOut(2);

if t2>Opt.cutoff; t2 = Opt.cutoff; end;
if isnan(t2); t2 = 0; end;
if t2<0; t2 = 0; end;

fit_out(2) = t2;

end
