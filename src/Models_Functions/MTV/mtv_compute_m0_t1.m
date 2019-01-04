function [M0, T1] = mtv_compute_m0_t1(data, flipAngles, TR, b1Map, roi, fixT1, verbose)

% function function [M0 T1] = fitData_MTV (data, flipAngles, TR [, b1Map, roi, fixT1, verbose])
% -----------------------------------------------------------
% This function performs a weighted-least squares data fit
% on SPGR T1-weighted data set
% INPUTS:
% data: width x length x slices x flipAngles matrix
% flipAngles: a vector of flip angles (in degrees) that corresponds to
% data(:,:,:,4)
% TR: in s
% b1Map: a width x length x slices matrix that contains the relative flip
% angle (i.e. if nominal alpha is 60, and measured alpha is 61, then b1Map
% = 61/60
% roi: binary mask (Matrix)
% fixT1: scalar or Matrix. If 0 --> do not fix T1.
% verbose: logical
%

if ndims(data)<3, data = permute(data(:),[2 3 4 1]); end
if (nargin < 4) || isempty(b1Map)
    dataSize = size(data);
    b1Map = ones([dataSize(1:end-1) 1]);
end

if nargin<5 || isempty(roi)
    dataSize = size(data);
    roi = ones(dataSize(1:end-1));
end

if nargin<6
    fixT1 = 0;
end

if nargin<7
    verbose = 0;
end

if max(size(b1Map) ~= dataSize(1:length(size(b1Map)))), error('B1 size is different from data size'); end

dims = size(data);
T1 = zeros([dims(1:end-1)]);
M0 = zeros([dims(1:end-1)]);

warning('off');
%sprintf('%s\n\n\n','loop over voxels...')
for vox=1:dims(1)*dims(2)*dims(3)
    %disp([sprintf('\b\b\b\b\b%3i',floor(vox/(dims(1)*dims(2)*dims(3))*100)) '%'])
    if roi(vox) && b1Map(vox)~=0

    kk=floor((vox-1)/(dims(1)*dims(2))); jj=floor((vox-kk*dims(1)*dims(2)-1)/(dims(1))); ii=vox-kk*dims(1)*dims(2)-jj*dims(1);
    kk=kk+1; jj=jj+1;
    %ii
        if ~fixT1
            %% T1 Mapping Using Variable Flip Angle SPGR Data With
            % Flip Angle Correction - Liberman, et al.
            y = squeeze(squeeze(data(ii,jj,kk, :)))./sin(flipAngles/180*pi*b1Map(vox))';
            x = squeeze(squeeze(data(ii,jj,kk, :)))./tan(flipAngles/180*pi*b1Map(vox))';

            % fit data
            param = polyfit(x,y,1);
%             fitresult = LinearFit(x, y, verbose);
%             param = coeffvalues(fitresult); % slope and intercept of the fitting
            param(isnan(param))=0;

%             ci = confint(fitresult,0.682); % confidence interval of the fitting (returns the slope and intercept of the lines framing the fit) -- corresponding to 2*sigma
%             ci(isnan(ci)) = 0;
%
            % compute PD and T1
            [~,T1(vox)]=getT1(param,TR);
        else
            %% if T1 is known
            T1(vox)=fixT1(min(vox,end));
        end
        %% Get M0
        [FA,iFA]=min(flipAngles);

        M0(vox)=getM0fromT1(T1(vox),TR(1),data(ii,jj,kk,iFA),FA*b1Map(vox));
        % add length of the confidence interval at 68.2% in the fourth
        % dimension

        if ~fixT1
%             [~,t1_min]=getT1(ci(1,:),TR);
%             [~,t1_max]=getT1(ci(2,:),TR);
%             M02(vox)=abs(getM0fromT1(t1_max,TR,data(ii,jj,kk,ialpha),alpha)-getM0fromT1(t1_min,TR,data(ii,jj,kk,ialpha),alpha));
%             T12(vox)=abs(t1_max-t1_min);
        end

    end
end
if ~fixT1
%    T1(:,:,:,2)=T12;
%     M0(:,:,:,2)=M02;
end
%display('...done')


function [fitresult, gof] = LinearFit(x, y, verbose)
%CREATEFIT(X,Y)
%  Create a fit.
%
%  Data for 'untitled fit 1' fit:
%      X Input : x
%      Y Output: y
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%
%  See also FIT, CFIT, SFIT.

%  Auto-generated by MATLAB on 22-Jan-2015 15:51:35


% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( x, y );

% Set up fittype and options.
ft = fittype( 'poly1' );

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft );

% Plot fit with data.
if verbose && max(xData~=0) && max(yData~=0)

    figure(100)
    h = plot( fitresult, xData, yData,'+');
    set(h,'MarkerSize',30)
    legend( h, 'y vs. x', 'untitled fit 1', 'Location', 'NorthEast' );
    p11 = predint(fitresult,x,0.95,'observation','off');
    hold on
    plot(x,p11,'m--'); drawnow;
    hold off
    % Label axes
    xlabel( 'x' );
    ylabel( 'y' );
    grid on
    saveas(gcf,['temp.jpg']);
end


function [M0,T1]=getT1(param,TR)
a=param(1); % slope
b=param(2); % intercept
if a>0
    T1 = -TR/log(a);
else  % due to noise or bad fitting
    T1 = 0.000000000000001;
end
M0 = b/(1-exp(-TR/T1));


function M0=getM0fromT1(T1,TR,S,FA)
% Volz, S., N�th, U., Deichmann, R., 2012. Correction of systematic errors in quantitative proton density mapping. Magn. Reson. Med. 68, 74?85.
% Steady state
ST=(1+exp(-TR./T1))./(1-cos(FA*pi/180).*exp(-TR./T1)).*sin(FA*pi/180);
% M0=RP*PD (RP=Receiver Profile)
M0=S/ST;
