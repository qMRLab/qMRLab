clear all;  clc; close all;

addpath('./data')
load('volume3DFSE.mat') %3D FSE SPGR dataset (1.5 T) used in in vivo experiment of '....'
%im=squeeze(im(:,:,19,:));
%% NOVIFAST's parameter definition
TR=9; %Repetition time [ms]
ini=[0.2,500]; %K [] and T1 [ms] initial constant maps for NOVIFAST 
options=struct('Direct',2); %If field 'Direct' is given, it means NOVIFAST is run in a blind mode, i.e., no convergence criterion. Just 5 iter are done.
%options=struct('Tol',1e-5,'Maxiter',20);  %If field 'Direct' does not exist, 'Tol' (l1 norm) and 'MaxIter' are then used to halt NOVIFAST
%% We call NOVIFAST
time=tic;
[ K, T1 ] = novifast_image( im, alpha, TR, options );
time=toc(time)
%% visualization
warning off
figure(1)
if numel(size(im))==4 %if im is a volume we visualize middle slice
    nslice=18;
    imshow(squeeze(T1(:,:,nslice)),[500,5000]) %A single slice is visualize
    title('Estimated in vivo T_1 map [ms]')
    colorbar
elseif numel(size(im))==3; 
    nslice=1;
    imshow(T1,[500,5000])
    title('Estimated in vivo T_1 map [ms]')
    colorbar
end
strg=['slice nz = ',num2str(nslice)];
text(104,11,strg,'fontsize',14,'Color','red')
strg2=['Dataset computation time = ',num2str(time), ' s'];
text(68,244,strg2,'fontsize',14,'Color','green')
