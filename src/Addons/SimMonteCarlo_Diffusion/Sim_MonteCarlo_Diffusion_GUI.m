function varargout = Sim_MonteCarlo_Diffusion_GUI(varargin)
% Protocol design for qMR: Optimize the stability of fitting parameters
% toward gaussian noise.
%
% Usage:
%   Click on update button to run the simulation
%   When Optimization is finished, Single Voxel Curve Simulation is
%     automatically performed using the optimized protocol. 
%   Save the protocol in text file using save button
%     
% Options:
%   # of volumes                Number of volumes in the optimized protocol
%   Population                  Population size
%   # of migration              Number of iteration before the optimizer
%                                stops. Note that you can stop the
%                                iterations during the optimization.
%
% Description:
% Use the Cramer-Rao Lower bound for objective function: <a href="matlab: web('https://en.wikipedia.org/wiki/Cramer-Rao_bound')">Wikipedia</a>
% Based on: Alexander, D.C., 2008. A general framework for experiment design in diffusion MRI and its application in measuring direct tissue-microstructure features. Magn. Reson. Med. 60, 439?448.


% Edit the above text to modify the response to help Sim_SimMCdiff

% Last Modified by GUIDE v2.5 26-Aug-2019 15:37:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Sim_SimMCdiff_OpeningFcn, ...
    'gui_OutputFcn',  @Sim_SimMCdiff_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before Sim_SimMCdiff is made visible.
function Sim_SimMCdiff_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.Model = varargin{1};
setappdata(0,'Model',handles.Model);

if ~isfield(handles,'opened')
    savedPacks = dir(fullfile(fileparts(which('Sim_MonteCarlo_Diffusion_GUI.m')),'savedPacks','*.mat'));
    set(handles.preset_packing,'String',{savedPacks.name});
    [axons, packing] = loadPreset(handles);
    handles.axonpacking.axons = axons;
    handles.axonpacking.packing = packing;
    
    % Statistics from the packing
    k=1;
    [FVF, FR, MVF, AVF] = compute_statistics(axons.d{k}/2, axons.Delta{k}, packing.final_positions{k}, [], axons.g_ratio{k});
    set(handles.tableVolumes,'Data',[FVF; FR; MVF; AVF])
    
    % set values
    slider_Naxons_Callback(handles.slider_Naxons, [], handles)
    slider_dvar_Callback(handles.slider_dvar, [], handles)
    slider_dmean_Callback(handles.slider_dmean, [], handles)
    slider_gap_Callback(handles.slider_gap, [], handles)
    slider_trans_Callback(handles.slider_trans, [], handles)
    slider_numelparticle_Callback(handles.slider_numelparticle, [], handles)
    slider_Dcoef_Callback(handles.slider_Dcoef, [], handles)
    
    % clear axe
    handles.opened = 1;
end
% Update handles structure
guidata(hObject, handles);


% UIWAIT makes Sim_SimMCdiff wait for user response (see UIRESUME)
% uiwait(handles.Simu);


% --- Outputs from this function are returned to the command line.
function varargout = Sim_SimMCdiff_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure



% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in SimMCdiffUpdate.
function SimMCdiffUpdate_Callback(hObject, eventdata, handles)
set(findobj('Name','SimMCdiff'),'pointer', 'watch'); drawnow;
MonteCarloSim(handles, handles.axonpacking.axons, handles.axonpacking.packing)
set(findobj('Name','SimMCdiff'),'pointer', 'arrow'); drawnow;



% GETAPPDATA
function varargout = GetAppData(varargin)
for k=1:nargin; varargout{k} = getappdata(0, varargin{k}); end

%SETAPPDATA
function SetAppData(varargin)
for k=1:nargin; setappdata(0, inputname(k), varargin{k}); end

% RMAPPDATA
function RmAppData(varargin)
for k=1:nargin; rmappdata(0, varargin{k}); end

% --------------------------------------------------------------------
function helpbutton_ClickedCallback(hObject, eventdata, handles)
doc Sim_MonteCarlo_Diffusion_GUI

function slider_gap_Callback(hObject, eventdata, handles)
%update_axonSetup(handles);
set(handles.text_gap,'String', ['Gap between axons: ' num2str(get(hObject,'Value')) 'um'])
function slider_dvar_Callback(hObject, eventdata, handles)
update_axonSetup(handles);
set(handles.text_dvar,'String', ['Diameter variance: ' num2str(get(hObject,'Value')) 'um'])
function slider_dmean_Callback(hObject, eventdata, handles)
update_axonSetup(handles);
set(handles.text_dmean,'String', ['mean diameter: ' num2str(get(hObject,'Value')) 'um'])
function slider_Naxons_Callback(hObject, eventdata, handles)
update_axonSetup(handles);
set(handles.text_Naxons,'String', ['# axons: ' num2str(round(get(hObject,'Value')))])


function [d, x0, side, axons] = update_axonSetup(handles)
k=1;
axons.N{k}      = round(get(handles.slider_Naxons,'Value'));
axons.d_mean{k} = get(handles.slider_dmean,'Value');
axons.d_var{k}  = get(handles.slider_dvar,'Value');
axons.Delta{k}  = get(handles.slider_gap,'Value'); 
axons.threshold_high{k} = 20;
axons.threshold_low{k}  = .1;
axons
[d, x0, side] = axons_setup(axons,'gamma', k, handles.axes_axonDist);

function run_pack_Callback(hObject, eventdata, handles)
k=1;
[d, x0, side, axons] = update_axonSetup(handles);

axons.d{k} = d;
axons.g_ratio{k} = compute_gratio(d);

% packing process of the axons
iter_max = 10000;
iter_fvf = iter_max/10;
[final_positions, final_overlap, fvf_historic] = process_packing(x0, d/2, axons.Delta{k}, side, iter_max, iter_fvf);

% store packing results
% main results
packing.initial_positions{k}    = reshape(x0,2,length(x0)/2);
packing.final_positions{k}      = final_positions;
% secondary results
packing.final_overlap{k}        = final_overlap;
packing.FVF_historic{k}         = fvf_historic;
packing.iter_max{k}             = iter_max;

% Statistics from the packing
[FVF, FR, MVF, AVF] = compute_statistics(axons.d{k}/2, axons.Delta{k}, packing.final_positions{k}, side, axons.g_ratio{k});
set(handles.tableVolumes,'Data',[FVF; FR; MVF; AVF])

if ishandle(201), close(201); end
plotPacking(handles,axons,packing)
handles.axonpacking.axons = axons;
handles.axonpacking.packing = packing;

guidata(hObject, handles);

function save_pack_Callback(hObject, eventdata, handles)
axons   = handles.axonpacking.axons;
packing = handles.axonpacking.packing;
fname = sprintf('pack_d%.1fvar%.1fgap%.1f.mat',axons.d_mean{1},axons.d_var{1},axons.Delta{1});
fname = fullfile(fileparts(which('Sim_MonteCarlo_Diffusion_GUI.m')),'savedPacks',fname);
fname = uiputfile('*.mat','Save Packing as...',fname);
if fname
    save(fname,'axons','packing')
    savedPacks = get(handles.preset_packing,'String');
    set(handles.preset_packing,'String',unique([savedPacks; {fname}]));
    savedPacks = get(handles.preset_packing,'String');
    set(handles.preset_packing,'Value',length(savedPacks));
end


function preset_packing_Callback(hObject, eventdata, handles)
[axons, packing] = loadPreset(handles);
handles.axonpacking.axons = axons;
handles.axonpacking.packing = packing;
k=1;
[FVF, FR, MVF, AVF] = compute_statistics(axons.d{k}/2, axons.Delta{k}, packing.final_positions{k}, [], axons.g_ratio{k});
set(handles.tableVolumes,'Data',[FVF; FR; MVF; AVF])

guidata(hObject, handles);

function     [axons, packing] = loadPreset(handles)
file = get(handles.preset_packing,'String');
load(file{get(handles.preset_packing,'Value')})
axons_setup(axons,'gamma', 1, handles.axes_axonDist);
plotPacking(handles,axons,packing)

function plotPacking(handles,axons,packing)
% plot disks
numelobj = size(packing.final_positions{1},2);
cen = packing.final_positions{1}'; cen=cen(:,[2 1]); cen=cen-repmat([mean(cen(:,1)) mean(cen(:,2))],[size(cen,1) 1]); % center position of the cells
cen = [cen, zeros(numelobj,1)];

% Radius of the "cells"
R = [axons.d{1}.*axons.g_ratio{1} axons.d{1}]/2; % internal / external diameter in um
R = R(:,2); %use external radius only.

t = linspace(0,2*pi);

axes(handles.axes_axonPack)
hold off
for k =1:size(R,1)
    plot(R(k,1)*cos(t)+cen(k,1), R(k)*sin(t)+cen(k,2),'b','linewidth',1);
    hold on
end
hold off
axis equal tight
xlabel x(\mum)
ylabel y(\mum)

function MonteCarloSim(handles, axons, packing)

% Read updated Model
Model_new = getappdata(0,'Model');
if ~isempty(Model_new) && strcmp(class(Model_new),class(handles.Model))
    handles.Model = Model_new;
end

axes(handles.uipanel12);

% Read parameters
numelparticle = round(get(handles.slider_numelparticle,'Value'));

trans_mean = get(handles.slider_trans,'Value'); % mean probability of penetrating the cell walls [0-1]
trans_var = 0.00;

D = get(handles.slider_Dcoef,'Value'); % Diffusion coefficient

scheme  = handles.Model.Prot.DiffusionData.Mat;
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
    set(ar,'facecolor', color, 'facealpha',0.1);
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
m1 = scatter3(positions(inisitu==1,1),positions(inisitu==1,2),positions(inisitu==1,3),'r.');
m2 = scatter3(positions(inisitu==0,1),positions(inisitu==0,2),positions(inisitu==0,3),'b.');

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
    m1 = scatter3(positions(inisitu==1,1),positions(inisitu==1,2),positions(inisitu==1,3),'r.');
    m2 = scatter3(positions(inisitu==0,1),positions(inisitu==0,2),positions(inisitu==0,3),'b.');
    
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

fig = figure(293);
set(fig,'Name','Monte-Carlo simulated Signal')
set(fig, 'Position', get(0, 'Screensize'));

data.SigmaNoise = 0.01;
subplot(3,1,1)
data.DiffusionData = signal_intra(:);
FitResults  = handles.Model.fit(data);
handles.Model.plotModel(FitResults, data); 
txt = get(gca,'Title');
set(txt,'String',sprintf(['intra axonal signal:\n' txt.String]));
set(txt,'Color',[1 0 0])
subplot(3,1,2)
data.DiffusionData = signal_extra(:);
FitResults  = handles.Model.fit(data);
handles.Model.plotModel(FitResults, data); 
txt = get(gca,'Title');
set(txt,'String',sprintf(['extra axonal signal:\n' txt.String]));
set(txt,'Color',[0 0 1])
subplot(3,1,3)
data.DiffusionData = signal(end,:)';
FitResults  = handles.Model.fit(data);
handles.Model.plotModel(FitResults, data); 
txt = get(gca,'Title');
set(txt,'String',sprintf(['full signal:\n' txt.String]));

uicontrol(293,'Style','pushbutton','String','Save','Callback',@(src,evnt) saveSignal(signal,signal_intra,signal_extra),'BackgroundColor',[0.0 0.65 1]);

% fprintf('\nbv = %g[sec/mm2]\nDELTA = %g[ms], delta = %g[ms]\n',bv,DELTA,delta);
fprintf('S/S0 = %1.3g\n', (signal(end,end)));
fprintf('ADC = %1.3g x10-3[mm2/sec]\n', (log(signal(end,end))./(-bv(end)))*1000);
fprintf('D = %1.3g x10-3[mm2/sec]\n', flight_mean^2/steptime/2/(mode3D+2))

toc

function saveSignal(signal,signal_intra,signal_extra)
fname = uiputfile('*.mat');
if fname
    signal = permute(signal,[1 3 4 2]);
    signal_intra = permute(signal,[2 3 4 1]);
    signal_extra = permute(signal,[2 3 4 1]);

    save(fname,'signal','signal_intra','signal_extra')
end

function slider_trans_Callback(hObject, eventdata, handles)
set(handles.text_trans,'String', ['Permeability: ' num2str(get(hObject,'Value'))])
function slider_numelparticle_Callback(hObject, eventdata, handles)
set(handles.text_numelparticle,'String', ['Number of particles: ' num2str(get(hObject,'Value'))])
function slider_bv_Callback(hObject, eventdata, handles)
set(handles.text_bv,'String', ['bvalue: ' num2str(get(hObject,'Value')) 'sec/mm2'])
function slider_Dcoef_Callback(hObject, eventdata, handles)
D = get(hObject,'Value');
set(handles.text_Dcoef,'String', sprintf('Diffusion coefficient: \n\tD = %.2gx 10-3 mm2/sec',D))
set(handles.text_Step,'String', sprintf('steptime = %.1g [ms]\nstepflight = %.1g [um]\n(stepflight = 4*D*steptime)',0.5,4*D*.5))


function preset_packing_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function slider_gap_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function slider_dvar_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function slider_dmean_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function slider_Naxons_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function slider_trans_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function slider_numelparticle_CreateFcn(hObject, eventdata, handles)
function slider_bv_CreateFcn(hObject, eventdata, handles)
function slider9_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function slider_Dcoef_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
