function varargout = Sim_MonteCarlo_Diffusion_GUI(varargin)
% ## Purpose
% This Monte Carlo simulator for 2D diffusion is able to generate synthetic diffusion signal from any 2D axon packing.
% 
% ## Approach
% First, the [axonpacking](https://github.com/neuropoly/axonpacking) software is used to generate dense packing of circles. 
% Then, the Monte Carlo simulator moves water molecules around in the packing and apply the phase shift induced by the diffusion gradients. 
% 
% ## Interface
% First step is to generate an axon packing. Pre-packed examples are
% proposed.
% 
% Then, when clicking on `Update` button, the Monte Carlo simulation runs in this packing.
% _Note: blues dots correspond to extra-axonal water molecules and red dots to intra-axonal water_
% _Note: The `MPG strength` and `Signal Strength` plots correspond to the last bvalue in the protocol. But Signal Strength is computed for all bvalues from the protocol._
% 
% Once the simulation is finished, synthetic data are plotted and fitted by the charmed model.
% The user is able to save this synthetic signal in a `.mat` file.
% 
% Authors: Yasuhiko Tachibana, Tanguy Duval, Tom Mingasson, 2019

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
    if ~ismac
        set(findobj(hObject,'Type','uicontrol'),'FontSize',7); 
    end % everything is bigger on windows or linux

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
axons.d_mean{k} = round(get(handles.slider_dmean,'Value')*10)/10;
set(handles.slider_dmean,'Value',axons.d_mean{k})
axons.d_var{k}  = round(get(handles.slider_dvar,'Value')*10)/10;
set(handles.slider_dvar,'Value',axons.d_var{k});
axons.Delta{k}  = get(handles.slider_gap,'Value'); 
axons.threshold_high{k} = 20;
axons.threshold_low{k}  = .1;
axons
[d, x0, side] = axons_setup(axons,'gamma', k, handles.axes_axonDist);
if ~ismac, set(handles.axes_axonDist,'FontSize',7); end

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
[fname, path] = uiputfile('*.mat','Save Packing as...',fname);
if fname
    save(fullfile(path,fname),'axons','packing')
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
if ~ismac, set(handles.axes_axonDist,'FontSize',7); end
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

if ~ismac, set(handles.axes_axonPack,'FontSize',7); end

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

D = get(handles.slider_Dcoef,'Value'); % Diffusion coefficient

handles.Model.Sim_MonteCarlo_Diffusion(numelparticle, trans_mean, D, packing, axons);

function slider_trans_Callback(hObject, eventdata, handles)
set(handles.text_trans,'String', ['Permeability: ' num2str(get(hObject,'Value'))])
function slider_numelparticle_Callback(hObject, eventdata, handles)
set(hObject,'Value',round(get(hObject,'Value')))
set(handles.text_numelparticle,'String', ['Number of particles: ' num2str(get(hObject,'Value'))])
function slider_bv_Callback(hObject, eventdata, handles)
set(handles.text_bv,'String', ['bvalue: ' num2str(get(hObject,'Value')) 'sec/mm2'])
function slider_Dcoef_Callback(hObject, eventdata, handles)
D = get(hObject,'Value');
set(handles.text_Dcoef,'String', sprintf('Diffusion coefficient: \n\tD = %.2gx 10-3 mm2/sec',D))
set(handles.text_Step,'String', sprintf('steptime = %.1g [ms]\nstepflight = %.1g [um]\n(stepflight^2 = 4*D*steptime)',0.5,sqrt(4*D*.5)))


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
