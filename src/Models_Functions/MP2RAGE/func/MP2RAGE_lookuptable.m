
function [Intensity T1vector IntensityBeforeComb]=MP2RAGE_lookuptable(nimages,MPRAGE_tr,invtimesAB,flipangleABdegree,nZslices,FLASH_tr,sequence,varargin)
% first extra parameter is the inversion efficiency
% second extra parameter is the alldata
%   if ==1 all data is shown
%   if ==0 only the monotonic part is shown
alldata=0;
if nargin >=9
    if ~isempty(varargin{2})
        alldata=varargin{2};
    end
end

invtimesa=invtimesAB(1);
invtimesb=invtimesAB(2);

B1vector=1;
flipanglea=flipangleABdegree(1);
flipangleb=flipangleABdegree(2);

T1vector=0.05:0.05:5;


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



j=0;
for T1=T1vector
    j=j+1;
    for MPRAGEtr=MPRAGE_tr
        for inversiontimesa=invtimesa
            for inversiontimesb=invtimesb
                m=0;
                for B1=B1vector
                    m=m+1;
                    %                 T1=1;%testline
                    inversiontimes2=[inversiontimesa inversiontimesb];
                    if and(and((diff(inversiontimes2))>=nZslices*FLASH_tr,inversiontimesa>=nZ_bef*FLASH_tr),inversiontimesb<=(MPRAGEtr-nZ_aft*FLASH_tr));
                        if nargin == 7
                            Signal(j,m,1:2)=1*MPRAGEfunc(nimages,MPRAGEtr,inversiontimes2,nZslices2,FLASH_tr,B1*[flipanglea flipangleb],sequence,T1);
                        else
                            if ~isempty(varargin{1})
                                Signal(j,m,1:2)=1*MPRAGEfunc(nimages,MPRAGEtr,inversiontimes2,nZslices2,FLASH_tr,B1*[flipanglea flipangleb],sequence,T1,varargin{1});
                            else
                                Signal(j,m,1:2)=1*MPRAGEfunc(nimages,MPRAGEtr,inversiontimes2,nZslices2,FLASH_tr,B1*[flipanglea flipangleb],sequence,T1);
                                
                            end;
                        end;
                    else
                        Signal(j,m,1:2)=0;
                    end;
                end;
            end;
        end;
    end;
end;
Intensity=squeeze(real(Signal(:,:,1).*conj(Signal(:,:,2)))./(abs(Signal(:,:,1)).^2+abs(Signal(:,:,2)).^2));
T1vector=squeeze(T1vector);
if alldata==0
    [a minindex]=max(Intensity);
    [a maxindex]=min(Intensity);
    Intensity=Intensity(minindex:maxindex);
    T1vector=T1vector(minindex:maxindex);
    IntensityBeforeComb=squeeze(Signal(minindex:maxindex,1,:));
    Intensity([1 end])=[0.5 -0.5]; % pads the look up table to avoid points that fall out ot the lookuptable
else
    Intensity=squeeze(real(Signal(:,:,1).*conj(Signal(:,:,2)))./(abs(Signal(:,:,1)).^2+abs(Signal(:,:,2)).^2));
    T1vector=squeeze(T1vector);
    IntensityBeforeComb=squeeze(Signal(:,1,:));
end;
