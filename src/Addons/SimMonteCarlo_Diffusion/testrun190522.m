clc
clear
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Simulation Parameters %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% MRI parameters
B0 = 3; % [T]

%%% Object (cells) parameters
numelobj = 70; % number of objects
d_mean = 5; % theoretical mean of axon diameters in um
d_var  = 1; % theoretical variance of axon diameters in um
gap = 1; % gap between the edge of axons in um
height = 150; % only used for visualization in 3D mode

trans_mean = 0.10; % mean probability of penetrating the cell walls [0-1]
trans_var = 0.02;

%%% Molecule parameters
numelparticle = 1000;
starting_range = 20; % the area where the molecules ditributes initially [us] 
flight_mean = 1; % mean displacement distance (if free diffusivity) at each step [um]
flight_var = 0.05;

%%% imaging sequence parameters
TE = 70; % [ms]
bv = 1000; % b-value [s/mm2]

%%% simulator parameters
steptime = 0.2; % each iteration (step) corresponds to "steptime"[ms]. 
mode3D = 1; % 1->3D, 0->2D

packingiter = 10000; % number of iteration for axon packing

%%%%% END %%%%%%


%posratio = 1; % one unit length corresponds to "posratio"[um] % fix to 1 in later version
sn = 0.000000001; % "small number" but larger than eps. Used to avoid molecules traped in a wall
%% axon packing
%[axons,packing] = func_axonpack_main(numelobj, d_mean, d_var, gap, packingiter);
load packsample.mat

%% setup figure
f = figure; cla
a1 = subplot(4,1,1); hold on; hold on; set(a1,'Ycolor','w','Xcolor','w');
a2 = subplot(4,1,2); hold on; ta2='Mean Square Displacement [mm2]'; title(ta2); set(a2,'fontsize',10); xlabel('time[ms]')%,'position',[0.95,-0.15])
a3 = subplot(4,1,3); hold on; title('MPG strength [mT/m]'); set(a3,'fontsize',10); xlabel('time[ms]') %,'position',[0.95,-0.15])
a4 = subplot(4,1,4); hold on; title('Signal strength (S/S0)'); set(a4,'fontsize',10); xlabel('time[ms]') %,'position',[0.95,-0.15])
bar2 = plot([0,TE],[1,1],'r','linestyle',':'); ylim([0 1]);

set(a1,'position',[0.03 0.50, 0.94, 0.50],'xtick',[],'ytick',[]);
set(a2,'position',[0.07 0.36, 0.86 0.10]);
set(a3,'position',[0.07 0.20, 0.86 0.10]);
set(a4,'position',[0.07 0.04, 0.86 0.10]);

axes(a1);cla;
axes(a2);cla;
axes(a3);cla;

p = get(f,'position');
p0 = get(0,'screensize');
p(1) = 0; p(2) = p0(4)*0.05; p(4) = p0(4)*0.9;
set(f,'position',p);

%%
totalsteps = TE/steptime;

%% define MPG
% MPG is defined by one vector (G_strength) and one matrix (G_direction).
% length and size are "totalsteps", and ["totalsteps",2]
% here a PGSE MPG is defined for example.

margin = 10; % [ms]. DELTA-delta, as well as time between RF and the first MPG lobe, and time between the 2nd MPG lobe to spin-echo.

delta = (TE-margin*3)/2; %ms
DELTA = delta + margin; %ms

larmor = 2*pi*42.58*10^6; %[(Hz)/(T.s)]
G = sqrt( (bv*10^21)/(larmor^2 * delta^2 * (DELTA - delta/3)) ); % Gradient strength [mT/m]
fprintf('gradient strength: %2g mT/m\n', G)

G_direction = zeros(totalsteps,3);
G_strength = zeros(totalsteps,1);

marginsteps = round(margin/steptime);
MPGsteps = round(delta/steptime);
ax = [1,0,0]; %supposing MPG parallel to x-axis is supposed in this example.
ax = ax/(norm(ax)+eps);

G_direction(marginsteps+1 : marginsteps + MPGsteps, :) = repmat(ax,MPGsteps,1); % 1st MPG lobe. 
G_strength(marginsteps+1 : marginsteps + MPGsteps) = G; 

G_direction(marginsteps*2 + MPGsteps + 1: marginsteps*2 + MPGsteps*2, :) = repmat(ax,MPGsteps,1); % 2nd MPG lobe.
G_strength(marginsteps*2 + MPGsteps + 1: marginsteps*2 + MPGsteps*2) = -G; % inverted.

subplot(a3)
X = 0:steptime:TE; Y = [0; G_strength];
%plot(X, Y,'k','linewidth',0.5); xlim([0 TE]); ylim([min(G_strength)*1.2, max(G_strength)*1.2]);
direc = unique(G_direction,'rows');
for d = 1:size(direc,1)
    rowindex = (G_direction(:,1) == direc(d,1)) & (G_direction(:,2) == direc(d,2)) & (G_direction(:,3) == direc(d,3));
    rowindex = [false; rowindex]; %#ok<AGROW>
    tempY = zeros(size(Y));
    tempY(rowindex) = Y(rowindex);
    ar = area(X,tempY,'linewidth',0.1);
    color = abs(direc(d,:)); color = [color(2:3), color(1)]; 
    set(ar,'facecolor', color, 'facealpha',0.1);
end
bar = plot([0,0],[-100,100],'r');
ylim([min(G_strength)*1.2, max(G_strength)*1.2]);


%% setup objects
trans = trans_mean + randn(numelobj,1) * trans_var; % proability of penetrating.
cen = packing.final_positions{1}'; cen=cen(:,[2 1]); cen=cen-repmat([mean(cen(:,1)) mean(cen(:,2))],[size(cen,1) 1]); % center position of the cells
cen = [cen, zeros(numelobj,1)];

% Radius of the "cells"
R = [axons.d{1}.*axons.g_ratio{1} axons.d{1}]; % internal / external diameter in um
R = R(:,2); %use external radius only.

figure(f);
t = linspace(0,2*pi);
subplot(a1);

[x,y,z] = cylinder; z = z-0.5;
if mode3D == 1
    for k = 1:numelobj
        X = x*R(k)+cen(k,1); Y = y*R(k)+cen(k,2); Z = z*height;
        f = surf(X,Y,Z);
        set(f,'facealpha',0,'edgealpha',0.05,'facecolor','b');
    end
end
for k =1:size(R,1)
    plot(R(k,1)*cos(t)+cen(k,1), R(k)*sin(t)+cen(k,2),'b','linewidth',1);
end

axis equal tight

%% starting position
inipos = (rand(numelparticle,3)-0.5) * starting_range;
inisitu= zeros(numelparticle,1); % starts from intra / extra object
for n = 1:numelparticle
    temp = cen(:,1:2) - repmat(inipos(n,1:2),numelobj,1);
    inisitu(n) = sum(temp(:,1).^2 + temp(:,2).^2 - R.^2 < 0);
end

positions = inipos;
subplot(a1);
if exist('m1','var') == 1
    delete(m1);
    delete(m2);
end
m1 = scatter3(positions(inisitu==1,1),positions(inisitu==1,2),positions(inisitu==1,3),'r.');
m2 = scatter3(positions(inisitu==0,1),positions(inisitu==0,2),positions(inisitu==0,3),'b.');

%%
tic
fprintf('totalsteps = %g\n',totalsteps)
phase = zeros(numelparticle,1);
savephase = zeros(numelparticle,totalsteps+1);
savedist = zeros(numelparticle,totalsteps+1);
integphase = zeros(1,totalsteps+1);
signal = ones(1,totalsteps+1);

th_xy = rand(numelparticle,1)*2*pi; % for the first displacement
th_z = (rand(numelparticle,1)-0.5) * pi *mode3D;

for s = 1:totalsteps
    flight = ones(numelparticle,1) * flight_mean + randn(numelparticle,1) * flight_var;
    tempG = G_strength(s);
    tempax = G_direction(s,:);

    parfor p = 1:numelparticle
        [positions(p,:), th_xy(p), th_z(p), phase(p)] =...
            func_simulstep190511(R,cen,trans,positions(p,:),th_xy(p),th_z(p),flight(p),phase(p),tempG,tempax,steptime,mode3D,sn);
    end
    savephase(:,s+1) = phase;
     [signal(s+1),integphase(s+1)] = func_integphase190511(phase);
    dist = (positions - inipos)*0.001; % [mm]
    savedist(:,s+1) =  dist(:,1).^2 + dist(:,2).^2 + dist(:,3).^2; %[mm^2]
    
    subplot(a1);
    delete(m1);
    delete(m2);
    m1 = scatter3(positions(inisitu==1,1),positions(inisitu==1,2),positions(inisitu==1,3),'r.');
    m2 = scatter3(positions(inisitu==0,1),positions(inisitu==0,2),positions(inisitu==0,3),'b.');
    
    subplot(a2);
    plot(0:steptime:steptime*s, mean(savedist(:,1:s+1),1),'b'); xlim([0 TE]);
    
    subplot(a3);
    delete(bar);
    bar = plot([steptime*s,steptime*s],[-100,100],'r');
    
    subplot(a4);
    delete(bar2);
    bar2 = plot([0,TE],[signal(s+1),signal(s+1)],'r','linestyle',':');
    plot(0:steptime:steptime*s, signal(1:s+1),'b'); xlim([0 TE]); ylim([0 1.2])

    drawnow
   
end
savephase = savephase - 2*pi*(savephase>pi);

% fprintf('\nbv = %g[sec/mm2]\nDELTA = %g[ms], delta = %g[ms]\n',bv,DELTA,delta);
fprintf('S/S0 = %1.3g\n', (signal(end)));
fprintf('ADC = %1.3g x10-3[mm2/sec]\n', (log(signal(end))/(-bv))*1000);

toc
