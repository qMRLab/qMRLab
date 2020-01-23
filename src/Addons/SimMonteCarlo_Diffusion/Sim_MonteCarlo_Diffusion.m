function [signal, signal_intra, signal_extra] = Sim_MonteCarlo_Diffusion(numelparticle, trans_mean, D, scheme, packing, axons)
% Sim_MonteCarlo_Diffusion(numelparticle, trans_mean, D, scheme, packing, axons)

trans_var = 0.00;
TE=max(scheme(:,7))*1e3;

%%% simulator parameters
starting_range = 10; % the area where the molecules ditributes initially [um] 
steptime = 0.5; % each iteration (step) corresponds to "steptime"[ms]. 
steptime = TE/round(TE/steptime);
mode3D = 0; % 1->3D, 0->2D
flight_mean = sqrt(2*(mode3D+2)*D*steptime); % mean displacement distance (if free diffusivity) at each step [um]
flight_var = 0;%0.05;
trans_mean = trans_mean; % mean probability of penetrating the cell walls [0-1]
trans_var = trans_var;
height = 150; % only used for visualization in 3D mode

sn = 0.000000001; % "small number" but larger than eps. Used to avoid molecules traped in a wall

%% setup figure
a1 = subplot(4,1,1); hold on; hold on; set(a1,'Ycolor','w','Xcolor','w');
a2 = subplot(4,1,2); hold on; ta2='Mean Square Displacement [mm2]'; title(ta2); set(a2,'fontsize',10); xlabel('time[ms]')%,'position',[0.95,-0.15])
a3 = subplot(4,1,3); hold on; title('MPG strength [mT/m]'); set(a3,'fontsize',10); xlabel('time[ms]') %,'position',[0.95,-0.15])
a4 = subplot(4,1,4); hold on; title('Signal strength (S/S0)'); set(a4,'fontsize',10); xlabel('time[ms]') %,'position',[0.95,-0.15])
bar2 = plot([0,TE],[1,1],'r','linestyle',':'); ylim([0 1]);

set(a1,'position',[0.03 0.60, 0.94 0.40]);
set(a2,'position',[0.07 0.45, 0.86 0.10]);
set(a3,'position',[0.07 0.25, 0.86 0.10]);
set(a4,'position',[0.07 0.05, 0.86 0.10]);

axes(a1);cla;
axes(a2);cla;
axes(a3);cla;

%%
TE = max(TE);
totalsteps = max(TE)/steptime;

%% define MPG
% MPG is defined by one vector (G_strength) and one matrix (G_direction).
% length and size are "totalsteps", and ["totalsteps",2]
% here a PGSE MPG is defined for example.

Ndwi = size(scheme,1); % number of DWI data
Sindex = 1:Ndwi;
delta = scheme(Sindex,6)*1e3;%(TE-margin*3)/2; %ms
DELTA = scheme(Sindex,5)*1e3;%delta + margin; %ms

larmor = 2*pi*42.58*10^6; %[(Hz)/(T.s)]
G = scheme(Sindex,4)*1e3; %sqrt( (bv*10^21)/(larmor^2 * delta^2 * (DELTA - delta/3)) ); % Gradient strength [mT/m]
fprintf('gradient strength: %2g mT/m\n', G(end))
bv = G.^2.*(larmor^2 * delta.^2 .* (DELTA - delta./3))*10^(-21);
fprintf('bvalue: %2g mm2/ms\n', bv(end))

G_direction = zeros(totalsteps,3,Ndwi);
G_strength = zeros(totalsteps,Ndwi);

margin = TE/2-delta-(DELTA-delta)/2; % [ms]. Time between RF and the first MPG lobe, and time between the 2nd MPG lobe to spin-echo.
marginsteps = round(margin/steptime);
MPGsteps = round(delta/steptime); % duration of the 1rst and 2nd lobes
MPGsep = DELTA - delta; % [ms].  time between the 1rst and the 2nd MPG lobe 
MPGsepsteps = round(MPGsep/steptime);

ax = scheme(Sindex,1:3); % [1 0 0] --> MPG parallel to x-axis.
%ax = ax./(norm(ax)+eps);

for idir = 1:Ndwi
    G_direction(marginsteps(idir)+1 : marginsteps(idir) + MPGsteps(idir), :,idir) = repmat(ax(idir,:),MPGsteps(idir),1); % 1st MPG lobe.
    G_strength(marginsteps(idir)+1 : marginsteps(idir) + MPGsteps(idir),idir) = G(idir);
    
    G_direction(marginsteps(idir) + MPGsteps(idir) + MPGsepsteps(idir) + 1: marginsteps(idir) + MPGsteps(idir)*2 + MPGsepsteps(idir), :,idir) = repmat(ax(idir,:),MPGsteps(idir),1); % 2nd MPG lobe.
    G_strength(marginsteps(idir) + MPGsteps(idir) + MPGsepsteps(idir) + 1: marginsteps(idir) + MPGsteps(idir)*2 + MPGsepsteps(idir),idir) = -G(idir); % inverted.
end

subplot(a3)
X = 0:steptime:TE(end); Y = [0; G_strength(:,end)];
%plot(X, Y,'k','linewidth',0.5); xlim([0 TE]); ylim([min(G_strength)*1.2, max(G_strength)*1.2]);
direc = unique(G_direction(:,:,end),'rows');
for d = 1:size(direc,1)
    rowindex = (G_direction(:,1,end) == direc(d,1)) & (G_direction(:,2,end) == direc(d,2)) & (G_direction(:,3,end) == direc(d,3));
    rowindex = [false; rowindex]; %#ok<AGROW>
    tempY = zeros(size(Y));
    tempY(rowindex) = Y(rowindex);
    ar = area(X,tempY,'linewidth',0.1);
    color = abs(direc(d,:)); color = [color(2:3), color(1)]; 
    if ~moxunit_util_platform_is_octave
    set(ar,'facecolor', color, 'facealpha',0.1);
    end
end
bar = plot([0,0],[-100,100],'r');
ylim([min(G_strength(:,end))*1.2, max(G_strength(:,end))*1.2]);


%% setup objects
numelobj = size(packing.final_positions{1},2);
trans = trans_mean + randn(numelobj,1) * trans_var; % proability of penetrating.
cen = packing.final_positions{1}'; cen=cen(:,[2 1]); cen=cen-repmat([mean(cen(:,1)) mean(cen(:,2))],[size(cen,1) 1]); % center position of the cells
cen = [cen, zeros(numelobj,1)];

% Radius of the "cells"
R = [axons.d{1}.*axons.g_ratio{1} axons.d{1}]/2; % internal / external diameter in um
R = R(:,2); %use external radius only.

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
xlabel x(\mum)
ylabel y(\mum)
%% starting position
inipos = (rand(numelparticle,3)-0.5) * starting_range;
inisitu= zeros(numelparticle,1); % starts from intra / extra object
for n = 1:numelparticle
    temp = cen(:,1:2) - repmat(inipos(n,1:2),numelobj,1);
    inisitu(n) = sum(temp(:,1).^2 + temp(:,2).^2 - R.^2 < 0);
end

% inipos = inipos(inisitu==1,:);
% inisitu = ones(sum(inisitu),1);
% numelparticle = sum(inisitu);
positions = inipos;
subplot(a1);
if exist('m1','var') == 1
    delete(m1);
    delete(m2);
end
m1 = scatter3(positions(inisitu==1,1),positions(inisitu==1,2),positions(inisitu==1,3),1,[1 0 0]);
m2 = scatter3(positions(inisitu==0,1),positions(inisitu==0,2),positions(inisitu==0,3),1,[0 0 1]);

%%
tic
fprintf('totalsteps = %g\n',totalsteps)
phase = zeros(numelparticle,Ndwi);
savephase = zeros(numelparticle,totalsteps+1);
savedist = zeros(numelparticle,totalsteps+1);
integphase = zeros(totalsteps+1,Ndwi);
signal = ones(totalsteps+1,Ndwi);

th_xy = rand(numelparticle,1)*2*pi; % for the first displacement
th_z = (rand(numelparticle,1)-0.5) * pi *mode3D;

if str2double(getenv('ISDISPLAY')) == 0
    disp('Total steps is set to 5 for testing.');
    totalsteps = 5;
end


for s = 1:totalsteps
    flight = ones(numelparticle,1) * flight_mean + randn(numelparticle,1) * flight_var;
    tempG = G_strength(s,:);
    tempax = G_direction(s,:,:);

    for p = 1:numelparticle
        [positions(p,:), th_xy(p), th_z(p), phase(p,:)] =...
            func_simulstep190511(R,cen,trans,positions(p,:),th_xy(p),th_z(p),flight(p),phase(p,:),tempG,tempax,steptime,mode3D,sn);
    end
    savephase(:,s+1) = phase(:,end);
     [signal(s+1,:),integphase(s+1,:)] = func_integphase190511(phase);
    dist = (positions - inipos)*0.001; % [mm]
    savedist(:,s+1) =  dist(:,1).^2 + dist(:,2).^2 + dist(:,3).^2; %[mm^2]
    
    subplot(a1);
    delete(m1);
    delete(m2);
    m1 = scatter3(positions(inisitu==1,1),positions(inisitu==1,2),positions(inisitu==1,3),1,[1 0 0]);
    m2 = scatter3(positions(inisitu==0,1),positions(inisitu==0,2),positions(inisitu==0,3),1,[0 0 1]);
    
    subplot(a2);
    plot(0:steptime:steptime*s, mean(savedist(:,1:s+1),1),'b'); xlim([0 TE]);
    
    subplot(a3);
    delete(bar);
    bar = plot([steptime*s,steptime*s],[-G(end),G(end)],'r');
    xlim([0 TE]);
    
    subplot(a4);
    delete(bar2);
    bar2 = plot([0,TE],[signal(s+1,end),signal(s+1,end)],'r','linestyle',':');
    plot(0:steptime:steptime*s, signal(1:s+1,end),'b'); xlim([0 TE]); ylim([0 1.2])

    drawnow
   
end

[signal_intra,integphase_intra] = func_integphase190511(phase(inisitu==1,:));
[signal_extra,integphase_extra] = func_integphase190511(phase(inisitu==0,:));

fprintf('S/S0 = %1.3g\n', (signal(end,end)));
fprintf('ADC = %1.3g x10-3[mm2/sec]\n', (log(signal(end,end))./(-bv(end)))*1000);
fprintf('D = %1.3g x10-3[mm2/sec]\n', flight_mean^2/steptime/2/(mode3D+2))

toc