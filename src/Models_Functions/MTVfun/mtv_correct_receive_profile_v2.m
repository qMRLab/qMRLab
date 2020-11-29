function mtv_correct_receive_profile_v2( fname_M0, fname_T1, WMMask, CSFMask , smoothness, pixdim)

[M0, hdr]=load_nii_data(fname_M0); M0=double(M0);
if ~exist('pixdim','var') 
    pixdim = hdr.dime.pixdim(2:4);
end
if ~exist('smoothness','var'), smoothness = 30; end

T1=double(load_nii_data(fname_T1));
mask = ~~load_nii_data(WMMask); %mask = mask & T1<1.1;

CSF = ~~load_nii_data(CSFMask);

A=zeros(1,7);B=zeros(1,7);
A(1) = 0.916 ; B(1) = 0.436; %litrature values


clear R1basis
% a basis for estimate the new A and B.
R1basis(:,2)=1./T1(mask);
R1basis(:,1)=1;

for ii=2:7
    PDp=1./(A(ii-1)+B(ii-1)./T1);
    %  PDp=PDp./median(PDp(BM1)); scale
    
    % the sensativity the recive profile
    RPp=M0./PDp;
    
    % Raw estimate
    g = mtv_fit3dsplinemodel(RPp,mask,[],smoothness,pixdim);  % Spline approximation
    %tmp = g; imagesc3D(tmp,[prctile(tmp(:),10) prctile(tmp(:),90)]); drawnow
    % calculate PD from M0 and RP
    PDi=M0./g;
    % solve for A B given the new PD estiamtion
    % ( 1./PDi(BM1) )= A* R1basis(:,1) + B*R1basis(:,2);

    co     = R1basis \ ( 1./PDi(mask) );
    A(ii)=co(1);
    B(ii)=co(2);
    
end
[xmin, xmax] = range_outlier(g);
imagesc3D(g,[xmin xmax]); drawnow;
save_nii_v2(g,'gain.nii.gz',fname_M0,64)
%% calcute the CSF PD

% find the white matter mean pd value from segmetation.
wmV=mean(PDi(mask & PDi>0));

% assure that the CSF ROI have pd value that are resnable.  The csf roi is a reslut of segmentation algoritim runed on the
% T1wighted image and cross section with T1 values. Yet  the ROI may have some contaminations or segmentation faules .
%Therefore, we create some low and up bonderies. No CSF with PD values that are the white matter PD value(too low) or double the white matter values (too high).
CSF1=CSF & PDi>wmV & PDi< wmV*2;

%To calibrate the PD we find the scaler that shift the csf ROI to be eqal to 1. --> PD(CSF)=1;
% To find the scale we look at the histogram of PD value in the CSF. Since it's not trivial to find the peak we compute the kernel density (or
% distribution estimates). for detail see ksdensity.m
%The Calibrain vhistogram of the PD values in the let find the scalre from the maxsimum of the csf values histogram
[csfValues, csfDensity]= ksdensity(PDi(CSF1), [min(PDi(CSF1)):0.001:max(PDi(CSF1))] );
CalibrationVal= csfDensity(csfValues==max(csfValues));% median(PD(find(CSF)));

%% calibrate the pd by the pd of the csf roi
WF=PDi./CalibrationVal(1);

% let cut outlayers
WF(WF<0)=0;
WF(WF>2)=2;
imagesc3D(1-WF,[0 0.35]); drawnow;

save_nii_v2(1-WF,'mtv.nii.gz','M0.nii',64)
