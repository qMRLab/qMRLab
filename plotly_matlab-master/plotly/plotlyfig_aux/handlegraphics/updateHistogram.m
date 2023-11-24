function obj = updateHistogram(obj,histIndex)

% x:...[DONE]
% y:...[DONE]
% histnorm:...[DONE]
% name:...[DONE]
% autobinx:...[DONE]
% nbinsx:...[DONE]
% xbins:...[DONE]
% autobiny:...[DONE]
% nbinsy:...[DONE]
% ybins:...[DONE]
% text:...[NOT SUPPORTED IN MATLAB]
% error_y:...[HANDLED BY ERRORBARSERIES]
% error_x:...[HANDLED BY ERRORBARSERIES]
% opacity: --- [TODO]
% xaxis:...[DONE]
% yaxis:...[DONE]
% showlegend:...[DONE]
% stream:...[HANDLED BY PLOTLYSTREAM]
% visible:...[DONE]
% type:...[DONE]
% orientation:...[DONE]

% MARKER:
% color: ...[DONE]
% size: ...[NA]
% symbol: ...[NA]
% opacity: ...[TODO]
% sizeref: ...[NA]
% sizemode: ...[NA]
% colorscale: ...[NA]
% cauto: ...[NA]
% cmin: ...[NA]
% cmax: ...[NA]
% outliercolor: ...[NA]
% maxdisplayed: ...[NA]

% MARKER LINE:
% color: ...[DONE]
% width: ...[DONE]
% dash: ...[NA]
% opacity: ...[TODO]
% shape: ...[NA]
% smoothing: ...[NA]
% outliercolor: ...[NA]
% outlierwidth: ...[NA]

%-------------------------------------------------------------------------%

%-AXIS INDEX-%
axIndex = obj.getAxisIndex(obj.State.Plot(histIndex).AssociatedAxis);

%-HIST DATA STRUCTURE- %
hist_data = get(obj.State.Plot(histIndex).Handle);

%-CHECK FOR MULTIPLE AXES-%
[xsource, ysource] = findSourceAxis(obj,axIndex);

%-AXIS DATA-%
eval(['xaxis = obj.layout.xaxis' num2str(xsource) ';']);
eval(['yaxis = obj.layout.yaxis' num2str(ysource) ';']);

%-------------------------------------------------------------------------%

%-hist xaxis-%
obj.data{histIndex}.xaxis = ['x' num2str(xsource)];

%-------------------------------------------------------------------------%

%-hist yaxis-%
obj.data{histIndex}.yaxis = ['y' num2str(ysource)];

%-------------------------------------------------------------------------%

%-bar type-%
obj.data{histIndex}.type = 'bar';

%-------------------------------------------------------------------------%

if isfield(hist_data, 'Orientation')
  %-Matlab 2014+ histogram() function-%
  orientation = hist_data.Orientation;
else
  %-Matlab <2014 hist() function-%
  orientation = histogramOrientation(hist_data);
end

switch orientation
    case {'vertical', 'horizontal'}

        %-------------------------------------------------------------------------%
        %-hist y data-%
        
        obj.data{histIndex}.x = hist_data.BinEdges(1:end-1) + 0.5*diff(hist_data.BinEdges);
        obj.data{histIndex}.width = diff(hist_data.BinEdges);%[hist_data.BinEdges(2:end), hist_data.Data(end)];
        obj.data{histIndex}.y = double(hist_data.Values);
        
        %-------------------------------------------------------------------------%

    case 'v'
        %-hist x data-%
        xdata = mean(hist_data.XData(2:3,:));
        
        %-------------------------------------------------------------------------%
        
        %-hist y data-%
        xlength = 0;
        for d = 1:length(xdata)
            obj.data{histIndex}.x(xlength + 1: xlength + hist_data.YData(2,d)) = repmat(xdata(d),1,hist_data.YData(2,d));
            xlength = length(obj.data{histIndex}.x);
        end
        
        %-------------------------------------------------------------------------%
        
        %-hist autobinx-%
        obj.data{histIndex}.autobinx = false;
        
        %-------------------------------------------------------------------------%
        
        %-hist xbins-%
        xbins.start = hist_data.XData(2,1);
        xbins.end = hist_data.XData(3,end);
        xbins.size = diff(hist_data.XData(2:3,1));
        obj.data{histIndex}.xbins = xbins; 
       
        %-------------------------------------------------------------------------%
        
        %-layout bargap-%
        obj.layout.bargap = (hist_data.XData(3,1)-hist_data.XData(2,2))/(hist_data.XData(3,1)-hist_data.XData(2,1));
        
        %-------------------------------------------------------------------------%
        
        
    case 'h'
        
        %-hist y data-%
        ydata = mean(hist_data.YData(2:3,:));
        
        %-------------------------------------------------------------------------%

        ylength = 0;
        for d = 1:length(ydata)
            obj.data{histIndex}.y(ylength + 1: ylength + hist_data.XData(2,d)) = repmat(ydata(d),1,hist_data.XData(2,d));
            ylength = length(obj.data{histIndex}.y);
        end
        
        %-------------------------------------------------------------------------%
        
        %-hist autobiny-%
        obj.data{histIndex}.autobiny = false;
        
        %-------------------------------------------------------------------------%
        
        %-hist ybins-%
        ybins.start = hist_data.YData(2,1);
        ybins.end = hist_data.YData(3,end);
        ybins.size = diff(hist_data.YData(2:3,1));
        obj.data{histIndex}.ybins = ybins; 
       
        %-------------------------------------------------------------------------%
        
        %-layout bargap-%
        obj.layout.bargap = (hist_data.XData(3,1)-hist_data.XData(2,2))/(hist_data.XData(3,1)-hist_data.XData(2,1));
        
        %-------------------------------------------------------------------------%
             
end

%-------------------------------------------------------------------------%

%-hist name-%
obj.data{histIndex}.name = hist_data.DisplayName;

%-------------------------------------------------------------------------%

%-layout barmode-%
obj.layout.barmode = 'group';

%-------------------------------------------------------------------------%

%-hist line width-%
obj.data{histIndex}.marker.line.width = hist_data.LineWidth;

%-------------------------------------------------------------------------%

%-hist opacity-%
if ~ischar(hist_data.FaceAlpha)
    obj.data{histIndex}.opacity = hist_data.FaceAlpha * 1.25;
end

%-------------------------------------------------------------------------%

%-marker data-%
obj.data{histIndex}.marker = extractPatchFace(hist_data);

%-------------------------------------------------------------------------%

%-change color when multiple histograms same axes-%
if min([xsource, ysource]) == 1
    obj.data{histIndex}.marker = rmfield(obj.data{histIndex}.marker, 'color');
end

%-------------------------------------------------------------------------%

%-hist visible-%
obj.data{histIndex}.visible = strcmp(hist_data.Visible,'on');

%-------------------------------------------------------------------------%

%-hist showlegend-%
leg = get(hist_data.Annotation);
legInfo = get(leg.LegendInformation);

switch legInfo.IconDisplayStyle
    case 'on'
        showleg = true;
    case 'off'
        showleg = false;
end

obj.data{histIndex}.showlegend = showleg;

%-------------------------------------------------------------------------%

end
