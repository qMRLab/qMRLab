function g = mtv_correct_receive_profile_v2( M0, T1, WMMask, smoothness, pixdim)

fprintf('\n Performing receive profile correction on white matter mask...              \n');

M0=double(M0);
if ~exist('smoothness','var'), smoothness = 30; end
T1=double(T1);
WMMask(isnan(WMMask))=0;
mask = ~~WMMask; %mask = mask & T1<1.1;

A=zeros(1,7);B=zeros(1,7);
A(1) = 0.916 ; B(1) = 0.436; %litrature values

% a basis for estimate the new A and B.
R1basis(:,2)=1./T1(mask);
R1basis(:,1)=1;
%tool = imtool3D(M0);
for ii=2:7
    PDp=1./(A(ii-1)+B(ii-1)./T1);
    %  PDp=PDp./median(PDp(BM1)); scale
    
    % the sensativity the recive profile
    RPp=M0./PDp;
    
    % Raw estimate
    g = mtv_fit3dsplinemodel(RPp,mask & ~isnan(RPp) & ~isinf(RPp),[],smoothness,pixdim(1:ndims(M0)));  % Spline approximation
    %tool.setImage(cat(4,tool.getImage,g))
    % calculate PD from M0 and RP
    PDi=M0./g;
    % solve for A B given the new PD estiamtion
    % ( 1./PDi(BM1) )= A* R1basis(:,1) + B*R1basis(:,2);

    co     = R1basis \ ( 1./PDi(mask) );
    A(ii)=co(1);
    B(ii)=co(2);
    
end

