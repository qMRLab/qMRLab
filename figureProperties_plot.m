function figureProperties_plot(structHandler)
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
    legendFontWeight = 26;

    fontName         = 'Times New Roman';

    %% Set properties
    %

    axis square
    set(structHandler.figure,'Position', [100, 100, 600, 600])

    structHandler.figure.CurrentAxes.Box        = 'on';
    structHandler.figure.CurrentAxes.LineWidth  = axesLineWidth;
    structHandler.figure.CurrentAxes.FontSize   = axesFontSize;
    structHandler.figure.CurrentAxes.FontWeight = 'bold';

    set(structHandler.xlabel,'FontWeight', 'bold' , 'FontSize', labelFontWeight , 'FontName', fontName);
    set(structHandler.ylabel,'FontWeight', 'bold' , 'FontSize', labelFontWeight , 'FontName', fontName);
    %set(structHandler.legend,'FontWeight', 'bold' , 'FontSize', legendFontWeight, 'FontName', fontName);

    legend boxoff
end