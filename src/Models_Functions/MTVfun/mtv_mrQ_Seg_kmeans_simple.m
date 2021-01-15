function [CSF, seg]=mtv_mrQ_Seg_kmeans_simple(T1,BM,M0,mmPerVox,CSFVal)
% function [CSF, seg]=mtv_mrQ_Seg_kmeans_simple(T1,BM,M0)
%
% Clips brain to ventricles area, then segments using k-means with three
% clusters.
%
% This function uses FSL to segment into three tissues. It takes the CSF
% tissue and restricts it by the T1 values. The CSF is also restricted to
% be in the center of the brain in a box of approximately 60mm x 80mm x
% 40mm. Assuming that the brain is in AC-PC space, this is where the
% ventricles should be.
% Assumption:
%       CSFVal: R1 for water at body temperature (in 1/sec). 
%                  Default is 0.35.
%
% ~INPUTS~
%       T1: VFA T1.
%       BM: Brain Mask.
%       M0: VFA M0.
%       CSFVal: Threshold on the R1 value of CSF (default=0.35s-1)
%
% ~OUTPUTS~
%       CSF: Refined mask of ventricules (box in the center + smooth)
%       seg: brain clustering (GM=1;DeepGray=2;WM=3;CSF=4)
%
% Adapted from:
% (C) Mezer lab, the Hebrew University of Jerusalem, Israel
%   2015
%
%


%% I. Loading and definitions
if ~exist('CSFVal','var')
    CSFVal=1/0.35; % R1 (in 1/sec) of water at body temp  (minimum value)
end
R1=1./T1;
BM = BM & ~isinf(R1);
%% II. Perform k-means in a "while" loop

    fprintf('\n Performing segmentation for CSF file ...              \n');

seg=zeros(size(R1));

mask= R1>CSFVal & BM;
notdone=0;

while notdone==0
    
    [IDX,C] =kmeans(R1(mask),3);
    seg(mask)=IDX;
    
    notdone=1;
    
    % Check we don't get a strange cluster that is very small in size.
    %(if so, this might be just noise)
    if  length(find(IDX==1))/length(IDX)<0.05
        mask=mask & seg~=1;
        notdone=0;
    end
    
    if  length(find(IDX==2))/length(IDX)<0.05
        mask=mask & seg~=2;
        notdone=0;
    end
    
    if  length(find(IDX==3))/length(IDX)<0.05
        mask=mask & seg~=3;
        notdone=0;
    end
end

% check if the clusters' means are too similar
if abs(1-C(1)/C(2))<0.1  &&  abs(1-C(1)/C(3))<0.1
    [IDX,C] =kmeans(R1(mask),1);
elseif abs(1-C(1)/C(2))<0.1
    [IDX,C] =kmeans(R1(mask),2);
elseif abs(1-C(1)/C(3))<0.1
    [IDX,C] =kmeans(R1(mask),2);
elseif abs(1-C(2)/C(3))<0.1
    [IDX,C] =kmeans(R1(mask),2);
end

%% III. Create segmentation file of the clipped brain 
seg=zeros(size(R1));
seg(mask)=IDX;

% The tissue with the highest value is white matter (WM), the tissue with
% the lowest value is gray matter (GM), and the tissue with the
% intermediate value is the deep nuclei and the tissue between the WM and
% the GM. 
%
% In some segmentations the lowest value is is air, intermediate is
% GM, and highest is WM. 
%
% Either way, the order is maintained and we get a segmentation of GM, WM
% and CSF.

[val,idx]=sort(C);
GMclass=1;DEEPclass=2;WMclass=3; CSFclass=4;

seg(seg==idx(1))=4; seg(seg==idx(2))=5;seg(seg==idx(3))=6;
seg(seg==4)=GMclass; seg(seg==5)=DEEPclass; seg(seg==6)=WMclass; 

CSF= R1<CSFVal & BM;
seg(CSF)=CSFclass; % any region that is mostly water.

% Clip mask size
boxsize = [30 40 20];
sz=size(CSF); szH=round(sz./2);
XX=boxsize(1)./round(mmPerVox(1));
YY=boxsize(2)./round(mmPerVox(2));
ZZ=boxsize(3)./round(mmPerVox(3));

CSF(szH(1)+XX:end,:,:)=0;
CSF(1:szH(1)-XX,:,:)=0;

CSF(:,1:szH(2)-YY,:)=0;
CSF(:,szH(2)+YY:end,:,:)=0;
if numel(szH)>2
    CSF(:,:,1:max(1,szH(3)-ZZ))=0;
    CSF(:,:,min(end,szH(3)+ZZ):end)=0;
end
%% IV. Smoothe in space
[CSF1] = ordfilt3D(CSF,6);
CSF1=CSF &  CSF1;

CSF2= CSF1 & R1<0.25 & R1>0.2 & M0<prctile(M0(BM),99);

%% V. Some issues

if length(find(CSF2))<200
           fprintf(['\n Warning: We could find only ' num2str(length(find(CSF2))) ' csf voxels. This makes the CSF WF estimation noisy. Consider reducing the CSF T1 threshold.              \n']);
end

% Larger ventricles region. 
% This mask is good for cases when CSF ventricles are hard to identify. 
% It may reduce the accuracy. 
CSF= CSF & R1<0.25 & R1>0.2 & M0<prctile(M0(BM),99);


