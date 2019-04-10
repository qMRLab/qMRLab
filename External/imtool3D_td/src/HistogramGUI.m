% HISTOGRAM FIG
function f = HistogramGUI(Map, Maskall, Color, label)
if ~exist('Maskall','var'), Maskall = true(size(Map)); end
if ~exist('Color','var'), Color = jet(double(max(1+Maskall(:)))); end
if ~exist('labels','var'), label = 'Pixel Intensity'; end

% Plot figure
f=figure('Position', [100 100 700 400], 'Resize', 'Off','Name','Histogram');

MatlabVer = version;

if str2double(MatlabVer(1))<8 || (str2double(MatlabVer(1))==8 && str2double(MatlabVer(3))<4)
    Maskall = logical(Maskall);
else
    h_plot = subplot(1,2,2); % Use subplot to give space for GUI elements
    h_plot.OuterPosition = [0.3 0 0.7 1.0];
end

% loop over mask
values = unique(Maskall(Maskall>0))';
if isempty(values), values = 0; end
for ic = 1:length(values)
    Selected = values(ic);
    Mask = Maskall == Selected;
    
    ii = find(Mask);
    nVox = length(ii);
    data = reshape(Map(ii),1,nVox);
    
    % Matlab < R2014b
    MatlabVer = version;
    if str2double(MatlabVer(1))<8 || (str2double(MatlabVer(1))==8 && str2double(MatlabVer(3))<4)
        defaultNumBins = max(5,round(length(data)/100));
        hist(data, defaultNumBins);
        % Label axes
        xlabel(label);
        ylabel('Counts');
        return;
    end
    
    % Matlab >= R2014b
    hold on
    h_hist(ic)=histogram(data);
    BinWidth(ic) = h_hist.BinWidth;
    
    hold off
    set(h_hist(ic),'FaceColor',Color(Selected+1,:),'FaceAlpha',0.3)
end

% set BinWidth
BinWidth = median(BinWidth);
for ic = 1:length(h_hist)
    h_hist(ic).BinWidth = BinWidth;
end

% Label axes
xlabel(label);
h_ylabel = ylabel('Counts');

% No. of bins GUI objects
h_text_bin = uicontrol(f,'Style','text',...
    'String', 'Width of bins:',...
    'FontSize', 14,...
    'Position',[5 20+300 140 34]);
h_edit_bin = uicontrol(f,'Style','edit',...
    'String', BinWidth,...
    'FontSize', 14,...
    'Position',[135 25+300 70 34]);
h_slider_bin = uicontrol(f,'Style','slider',...
    'Min',BinWidth/10,'Max',BinWidth*10,'Value',BinWidth,...
    'SliderStep',[1/(100-1) 1/(100-1)],...
    'Position',[205 26+300 10 30],...
    'Callback',{@sl_call,{h_hist h_edit_bin}});
h_edit_bin.Callback = {@ed_call,{h_hist h_slider_bin}};

% Min-Max GUI objects
h_text_min = uicontrol(f,'Style','text',...
    'String', 'Min',...
    'FontSize', 14,...
    'Position',[0 20+200 140 34]);
BinLimits = cat(1,h_hist.BinLimits);
h_edit_min = uicontrol(f,'Style','edit',...
    'String', min(BinLimits(:,1)),...
    'FontSize', 14,...
    'Position', [35 20+180 70 34]);
h_text_max = uicontrol(f,'Style','text',...
    'String', 'Max',...
    'FontSize', 14,...
    'Position',[130 20+200 40 34]);
h_edit_max = uicontrol(f,'Style','edit',...
    'String', max(BinLimits(:,2)),...
    'FontSize', 14,...
    'Position', [116 20+180 70 34]);

set(h_edit_min,'Callback',{@minmax_call,{h_hist h_edit_min h_edit_max data}})
set(h_edit_max,'Callback',{@minmax_call,{h_hist h_edit_min h_edit_max data}})


% Normalization GUI objects
h_text_min = uicontrol(f,'Style','text',...
    'String', 'Normalization mode',...
    'FontSize', 14,...
    'Position',[30 20+40 180 34]);
h_popup_norm = uicontrol(f,'Style','popupmenu',...
    'String', {'Count',...
    'Cumulative count',...
    'Probability',...
    'PDF',...
    'CDF'},...
    'FontSize', 14,...
    'Position', [30 20+20 180 34],...
    'Callback',{@norm_call,{h_hist h_ylabel}});


% Histogram GUI callbacks
function [] = sl_call(varargin)
% Callback for the histogram slider.
[h_slider_bin,h_cell] = varargin{[1,3]};
h_hist = h_cell{1};
h_edit_bin = h_cell{2};
for ic = 1:length(h_hist)
    h_hist(ic).BinWidth = h_slider_bin.Value;
end
h_edit_bin.String = h_slider_bin.Value;

function [] = ed_call(varargin)
% Callback for the histogram edit box.
[h_edit_bin,h_cell] = varargin{[1,3]};
h_hist = h_cell{1};
h_slider_bin = h_cell{2};

for ic=1:length(h_hist)
    h_hist(ic).BinWidth = max(eps,str2double(h_edit_bin.String));
end
h_slider_bin.Value = round(str2double(h_edit_bin.String));

function [] = minmax_call(varargin)
% Callback for the histogram bin bounds recalculate box.
h_cell = varargin{3};
h_hist = h_cell{1};
h_min = h_cell{2};
h_max = h_cell{3};

% Mask data out of range of min-max
minVal = str2double(h_min.String);
maxVal = max(minVal,str2double(h_max.String));

for ic = 1:length(h_hist)
    h_hist(ic).BinLimits = [minVal maxVal];
end

function [] = norm_call(varargin)
% Callback for the histogram edit box.
[h_popup_norm,h_cell] = varargin{[1,3]};
h_hist = h_cell{1};
h_ylabel = h_cell{2};

menu_status = h_popup_norm.String{h_popup_norm.Value};

for ic=1:length(h_hist)
    switch menu_status
        case 'Count'
            h_hist(ic).Normalization = 'count';
        case 'Cumulative count'
            h_hist(ic).Normalization = 'cumcount';
        case 'Probability'
            h_hist(ic).Normalization = 'probability';
        case 'PDF'
            h_hist(ic).Normalization = 'pdf';
        case 'CDF'
            h_hist(ic).Normalization = 'cdf';
    end
end
h_ylabel.String = menu_status;
