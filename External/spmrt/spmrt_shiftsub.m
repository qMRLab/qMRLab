function [xd, yd, delta, deltaCI] = spmrt_shiftsub(pair1,pair2,mask,plotshift,threshold)

% Compare pairs of test-retest images using a shift function analysis for dependent measures.
% For each pair, we compute the difference image, which tells how much different in each voxel.
% From the difference images, we run shift function analysis, which then
% tells if differences, i.e. reliability in measurements, are similar
% between pairs (for instance is the reliability of a given MRI sequence is
% the same as another sequence, tested for different level of
% reliability/values)
%
% FORMAT [dd delta deltaCI xd yd] = spmrt_shift(image1,image2,mask,plotshift,threshold)
%
% INPUT if no input the user is prompted
%       threshold (optional) if mask is not binary, threshold to apply
%
% OUTPUT xd and yd are the Harell-Davis estimators of each pair difference
%        delta and deltaCI the result of the shift function analysis between difference images
%
% Cyril Pernet
% --------------------------------------------------------------------------
% Copyright (C) spmrt

spm('defaults', 'FMRI');
if nargin < 5; threshold = []; end 
if nargin < 4; plotshift = 'yes'; threshold = []; end 

if nargin == 0
    [pair1,sts] = spm_select(2,'image','select images for pair 1',{},pwd,'.*',1);
    if sts == 0
        return
    end
    
    
    [pair2,sts] = spm_select(2,'image','select images for pair 2',{},pwd,'.*',1);
    if sts == 0
        return
    end
    
    [mask,sts] = spm_select(1,'image','select mask image',{},pwd,'.*',1);
    if sts == 0
        return
    end
    
    plotshift = 'yes'; % if user if prompt to enter data then return a figure
end


%% Get the data
if exist('threshold','var') && ~isempty(threshold)
    X = spmrt_getdata(pair1(1,:),pair1(2,:),mask,threshold);
    Y = spmrt_getdata(pair2(1,:),pair2(2,:),mask,threshold);
else
    X = spmrt_getdata(pair1(1,:),pair1(2,:),mask);
    Y = spmrt_getdata(pair2(1,:),pair2(2,:),mask);
end

nx = size(X,1);
if any(sum(X,1) == 0)
    error('at least one image in the 1st pair is empty')
end
A = X(:,2)-X(:,1);

ny = size(Y,1);
if any(sum(Y,1) == 0)
    error('at least one image in the 2nd pair is empty')
end
B = Y(:,2)-Y(:,1);

if nx ~= ny
    error('unexpectedly the number of voxels from each pairs differ despite using the same mask')
end

clear X Y

% Compute Harell-Davis estimates and Shift function
c=(37./n.^1.4)+2.75; % The constant c was determined so that the simultaneous 
                     % probability coverage of all 9 differences is
                     % approximately 95% when sampling from normal
                     % distributions
nboot = 200;         % default suggested by Wilcox


% Get >>ONE<< set of B bootstrap samples
% The same set is used for all nine quantiles being compared
btable = zeros(n,nboot);
for b=1:nboot
    btable(:,b) = randsample(1:n,n,true);
end

xd = NaN(1,9);
yd = NaN(1,9);
delta = NaN(1,9);
deltaCI = NaN(9,2);

for d=1:9
   fprintf('estimating decile %g\n',d)
   xd(d) = spmrt_hd(A,d./10);
   yd(d) = spmrt_hd(B,d./10);
   delta(d) = yd(d) - xd(d);
   bootdelta =spmrt_hd(B(btable),d./10)- spmrt_hd(A(btable),d./10);
   delta_bse = std(bootdelta,0);
   deltaCI(d,1) = yd(d)-xd(d)-c.*delta_bse;
   deltaCI(d,2) = yd(d)-xd(d)+c.*delta_bse;
end


%% figure
if strcmpi(plotshift,'yes')
    figure('Name','Shit function between image voxel values');set(gcf,'Color','w');
    plot(xd,delta,'ko'); hold on
    fillhandle=fill([xd fliplr(xd)],[deltaCI(:,1)' fliplr(deltaCI(:,2)')],[1 0 0]);
    set(fillhandle,'LineWidth',2,'EdgeColor',[1 0 0],'FaceAlpha',0.2,'EdgeAlpha',0.8);%set edge color
    refline(0,0); xlabel('pair 1 (image 2 - image 1)','FontSize',14)
    ylabel('Delta','FontSize',14); set(gca,'FontSize',12)
    grid on; box on
end



  















