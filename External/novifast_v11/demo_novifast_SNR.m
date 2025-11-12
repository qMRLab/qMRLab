clear all;  clc; close all;
warning off
addpath('./data')
load('slicePhantom.mat')

%% we choose a range of possible SNR
SNR90=[200,300,400,600,700,1000,inf];
itermax=15;

for n=1:numel(alpha)
    S(:,:,n)=Kgt.*(1-exp(-TR./T1gt)).*sind(alpha(n))./(1-exp(-TR./T1gt).*cosd(alpha(n)));
end


for snr=1:numel(SNR90)
    for iter=0:itermax
        %% We add noise
        K=mean(  Kgt(mask==1)./(SNR90(snr)*sigma_map(mask==1)));
        sigma_map2=K*sigma_map;
        sigma=repmat(sigma_map2,1,1,size(S,3));
        W=sigma.*(randn(size(S))+1i*randn(size(S)));
        im=abs(S+W);
        %% NOVIFAST's parameter definition
        ini=[0.2,1000]; %K [] and T1 [ms] initial constant maps for NOVIFAST 
        if iter==0
            T1=ini(2).*mask;
        else
            options=struct('Direct',iter); %If field 'Direct' is given, it means NOVIFAST is run in a blind mode, i.e., no convergence criterion. Just 5 iter are done.
            [K, T1] = novifast_image( im, alpha, TR, options, mask );
        end
        Erraray(snr,iter+1)=100*mean(abs(T1gt(mask==1)-T1(mask==1))./T1gt(mask==1));
        T1array(:,:,snr,iter+1)=T1;
    end
end

for snr=1:numel(SNR90)
    str=['SNR_{90} = ', num2str(SNR90(snr))];
    STR{snr}=str;
    T1snr=[];
    for iter=0:itermax
     T1snr=cat(2,T1snr,squeeze(T1array(:,:,snr,iter+1)));
    end
    T1array2(:,:,snr)=T1snr;
end

T1array3=[];
for snr=1:numel(SNR90)
    T1array3=cat(1,T1array3,squeeze(T1array2(:,:,snr)));
end
 
T1gtarray3=repmat(T1gt.*mask,[numel(SNR90),itermax+1]);
T1array3_margin=padarray(T1array3,[0,50],0,'pre');
T1array3_margin=padarray(T1array3_margin,[50,0],0,'pre');
 
figure(1)
imshow(T1array3_margin,[0,5000])
title('Estimated T_1 maps [ms] for several SNRs and iterations')
colorbar

for n=1:numel(SNR90)
    text(10, 103+(n-1)*114,'SNR_{90}','fontsize',11,'Color','red');
    text(10, 123+(n-1)*114, num2str(SNR90(n)),'fontsize',11,'Color','red');
end
for iter=0:itermax
    text(87+(iter)*94, 29,'k = ','fontsize',11,'Color','red');
    text(87+(iter)*94, 49, num2str(iter),'fontsize',11,'Color','red');
end

Error_map=100*abs(T1array3-T1gtarray3)./T1gtarray3;
Error_map_margin=padarray(Error_map,[0,50],0,'pre');
Error_map_margin=padarray(Error_map_margin,[50,0],0,'pre');

figure(2)
imshow(Error_map_margin,[0,50])
title('Relative error T_1 maps [%] for several SNRs and iterations')
colormap hot
colorbar

for n=1:numel(SNR90)
    text(2, 103+(n-1)*114,'SNR_{90}','fontsize',11,'Color','green');
    text(2, 123+(n-1)*114, num2str(SNR90(n)),'fontsize',12,'Color','green');
end
for iter=0:itermax
    text(87+(iter)*94, 29,'k = ','fontsize',11,'Color','green');
    text(87+(iter)*94, 49, num2str(iter),'fontsize',11,'Color','green');
end

figure(3)
plot(0:itermax,Erraray')
xlabel('k (iterations)')
ylabel('|T1_{gt} - T1^k| /  T1_{gt}')
title('Relative error T_1 [%] for several SNRs and iterations')
legend(STR,'location','NorthEast','Position',[0.610731323691343 0.461340323166312 0.161308516638466 0.438044662309368]);
