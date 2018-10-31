function [r, fig, stats] = correlationPlot(varargin)
varargin = [varargin, 'ProcessCorrelationOnly','On'];
[~, fig, stats] = BlandAltman(varargin{:});
r = stats.r;
