function [B1vector Intensity Signal]=B1mappingSa2RAGElookuptable(nimage,MPRAGE_tr,invtimesAB,flipangleABdegree,nZslices,FLASH_tr,varargin)
% usage
% [B1map]=B1mappingSa2RAGE(Rationii,nimage,MPRAGE_tr,invtimesAB,flipangleABdegree,nZslices,FLASH_tr,varargin)
% varargin{1} is a phase image
%varargin{2} is the T1average

% size(varargin,2)
if size(varargin,2)<2
    T1average=1.5;
else
    T1average=varargin{2};
end;
T1average;
B1vector=0.005:0.005:2.5;


if length(nZslices)==2
    nZ_bef=nZslices(1);
    nZ_aft=nZslices(2);
    nZslices2=(nZslices);
    nZslices=sum(nZslices);
    
elseif     length(nZslices)==1
    nZ_bef=nZslices/2;
    nZ_aft=nZslices/2;
    nZslices2=(nZslices);
end;



m=0;
for B1=B1vector
    m=m+1;
    if and(and((diff(invtimesAB))>=nZslices*FLASH_tr,invtimesAB(1)>=nZ_bef*FLASH_tr),invtimesAB(2)<=(MPRAGE_tr-nZ_aft*FLASH_tr));
        Signal(m,1:2)=1*MPRAGEfunc(nimage,MPRAGE_tr,invtimesAB,nZslices2,FLASH_tr,B1*[flipangleABdegree],'normal',T1average,-cos((B1*pi/2)));
    else
        Signal(m,1:2)=0;
    end;
end;

Intensity=squeeze(real(Signal(:,1))./(real(Signal(:,2))));
B1vector=squeeze(B1vector);
