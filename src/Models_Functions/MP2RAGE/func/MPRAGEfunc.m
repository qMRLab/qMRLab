function signal=MPRAGEfunc(nimages,MPRAGE_tr,inversiontimes,nZslices,FLASH_tr,flipangle,sequence,T1s,varargin);


if strcmp(sequence,'normal')
    normalsequence=true;
    waterexcitation=false;
else
    normalsequence=false;
    waterexcitation=true;
    B0=7;
FatWaterCSppm=3.3;% ppm
gamma=42.576;%MHz/T
pulseSpace=1/2/(FatWaterCSppm*B0*gamma);

end
M0=1;
%time=linspace(0,MPRAGE_tr,100);

fliprad=flipangle/180*pi;%conversion from degrees to radians
if nimages~=length(fliprad)
    temp=fliprad;
    for k=1:(nimages)
        fliprad(k)=temp;
    end;
end;


%ideally inversionefficiency=1;
if nargin==9
    if ~isempty(varargin{1})
    inversionefficiency=varargin{1};
    else
    inversionefficiency=0.96; %inversion efficiency of the Siemens MP2RAGE PULSE
    
    end;
    
    else
    
    inversionefficiency=0.96; %inversion efficiency of the Siemens MP2RAGE PULSE
end

if length(nZslices)==2
    nZ_bef=nZslices(1);
    nZ_aft=nZslices(2);
    nZslices=sum(nZslices);
elseif     length(nZslices)==1
    nZ_bef=nZslices/2;
    nZ_aft=nZslices/2;
end;
%% calculating the relevant timing and associated values

if normalsequence
    
    E_1=exp(-FLASH_tr./T1s);    %recovery between two excitaion
    TA=nZslices*FLASH_tr;
    TA_bef=nZ_bef*FLASH_tr;
    TA_aft=nZ_aft*FLASH_tr;

    TD(1)=inversiontimes(1)-TA_bef;
    E_TD(1)=exp(-TD(1)./T1s);
    TD(nimages+1)=MPRAGE_tr-inversiontimes(nimages)-TA_aft;
    E_TD(nimages+1)=exp(-TD(nimages+1)./T1s);
    if nimages>1
        for k=2:(nimages)
            TD(k)=inversiontimes(k)-inversiontimes(k-1)-TA;
            E_TD(k)=exp(-TD(k)./T1s);
        end;
    end;
    for k=1:(nimages)
        cosalfaE1(k)=cos(fliprad(k))*(E_1);
        oneminusE1(k)=1-E_1;
        sinalfa(k)=sin(fliprad(k));
    end;
    
end;
if waterexcitation
    
    E_1=exp(-FLASH_tr./T1s);
    E_1A=exp(-pulseSpace./T1s);
    E_2A=exp(-pulseSpace./0.06);%60 ms is an extimation of the T2star.. not very relevant
    E_1B=exp(-(FLASH_tr-pulseSpace)./T1s);
    
    TA=nZslices*FLASH_tr;
    TA_bef=nZ_bef*FLASH_tr;
    TA_aft=nZ_aft*FLASH_tr;
    
    TD(1)=inversiontimes(1)-TA_bef;
    E_TD(1)=exp(-TD(1)./T1s);
    TD(nimages+1)=MPRAGE_tr-inversiontimes(nimages)-T_aft;
    E_TD(nimages+1)=exp(-TD(nimages+1)./T1s);
    
    if nimages>1
        for k=2:(nimages)
            TD(k)=inversiontimes(k)-inversiontimes(k-1)-TA;
            E_TD(k)=exp(-TD(k)./T1s);
        end;
    end;
    
    for k=1:(nimages)
        cosalfaE1(k)=(cos(fliprad(k)/2)).^2*(E_1A*E_1B)-(sin(fliprad(k)/2)).^2*(E_2A*E_1B);
        oneminusE1(k)=(1-E_1A)*cos(fliprad(k)/2)*E_1B+(1-E_1B);
        sinalfa(k)=sin( fliprad(k) / 2).*cos(fliprad(k)/2).*(E_1A+E_2A);
    end;
    
end;

%% steady state calculation

MZsteadystate=1./(1+inversionefficiency*(prod(cosalfaE1))^(nZslices).*prod(E_TD));

MZsteadystatenumerator=M0*(1-E_TD(1));
for k=1:(nimages)
    %term relative to the image aquisition;
    MZsteadystatenumerator=MZsteadystatenumerator*(cosalfaE1(k))^nZslices...
        +M0.*(1-E_1).*(1-(cosalfaE1(k))^nZslices)...
        ./(1-(cosalfaE1(k)));
    
    %term for the relaxation time after it;
    MZsteadystatenumerator=MZsteadystatenumerator.*E_TD(k+1)+M0*(1-E_TD(k+1));
    
end;

MZsteadystate=MZsteadystate.*MZsteadystatenumerator;
% MZsteadystate=1;
%% signal
m=1;
temp=(-inversionefficiency*MZsteadystate*E_TD(1)+M0.*(1-E_TD(1))).*(cosalfaE1(m)).^(nZ_bef)+...
    M0.*(1-E_1).*(1-(cosalfaE1(m))^(nZ_bef))...
    ./(1-(cosalfaE1(m)));
signal(1)=sinalfa(m)*temp ;

if nimages>1
    for m=2:(nimages)
        temp=temp*(cosalfaE1(m-1))^(nZ_aft)+...
            M0.*(1-E_1).*(1-(cosalfaE1(m-1))^(nZ_aft))...
            ./(1-(cosalfaE1(m-1)));
        temp=(temp*E_TD(m)+M0*(1-E_TD(m))).*(cosalfaE1(m))^(nZ_bef)+...
            M0.*(1-E_1).*(1-(cosalfaE1(m))^(nZ_bef))...
            ./(1-(cosalfaE1(m)));
        signal(m)= sinalfa(m)*temp;
        
    end;
end;


