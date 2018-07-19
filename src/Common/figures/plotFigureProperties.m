function plotFigureProperties(structHandler)
%PLOTFIGUREPROPERTIES Set custom figure properties for plots
%
%   --arg--
%   structHandler: a struct with the following attributes:
%                   .figure: figure handler
%                   .xlabel: xlabel handler
%                   .ylabel: ylabel handler
%                   .legend: ledend handler
%

    %% Define default properties
    %

    axesLineWidth    = 3;
    axesFontSize     = 20;

    labelFontWeight  = 34;
    legendFontWeight = 16;

    fontName         = 'Times New Roman';

    %% Set properties
    %

    axis square
    set(structHandler.figure,'Position', [100, 100, 600, 600])

    set(structHandler.xlabel,'FontWeight', 'bold' , 'FontSize', labelFontWeight , 'FontName', fontName);
    set(structHandler.ylabel,'FontWeight', 'bold' , 'FontSize', labelFontWeight , 'FontName', fontName);
    set(structHandler.legend,'FontWeight', 'bold' , 'FontSize', legendFontWeight, 'FontName', fontName);
    
    if isOctave
        set(gca, "linewidth", axesLineWidth, "fontsize", axesFontSize)
    else
        structHandler.figure.CurrentAxes.Box        = 'on';
        structHandler.figure.CurrentAxes.LineWidth  = axesLineWidth;
        structHandler.figure.CurrentAxes.FontSize   = axesFontSize;
        structHandler.figure.CurrentAxes.FontWeight = 'bold';
    end
    legend boxoff
    
    %% Loop through plots to adjust linewidths
    %
    
    if ~isOctave
        numPlots = length(structHandler.plot);
    
        for ii = 1:numPlots
            structHandler.plot{ii}.LineWidth = 4;
        end
    end
end

