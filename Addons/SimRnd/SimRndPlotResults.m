% PLOT DATA
% SimRndPlotResults(RndParam,SimRndResults,PlotType,Xdata,Ydata)
% SimRndPlotResults(RndParam,SimRndResults,'Input parameters','F','Voxels count')

function SimRndPlotResults(RndParam,SimRndResults,PlotType,Xdata,Ydata)

switch PlotType
    case 'Input parameters'
        hist(RndParam.(Xdata), 30);
        xlabel(['Input ', Xdata], 'FontWeight', 'Bold');
        ylabel(Ydata, 'FontWeight',' Bold');
    case 'Fit results'
        hist(SimRndResults.(Xdata), 30);
        xlabel(['Fitted ', Xdata], 'FontWeight','Bold');
        ylabel(Ydata, 'FontWeight','Bold');
    case 'Input vs. Fit'
        plot(RndParam.(Xdata), SimRndResults.(Ydata),'.');
        xlabel(['Input ' , Xdata], 'FontWeight','Bold');
        ylabel(['Fitted ', Ydata], 'FontWeight','Bold');
    case 'Error'
        hist(SimRndResults.Error.(Xdata), 30);
        xlabel(['Error ', Xdata], 'FontWeight','Bold');
        ylabel(Ydata, 'FontWeight','Bold');
    case 'Pct error'
        hist(SimRndResults.PctError.(Xdata), 30);
        xlabel(['Pct Error ', Xdata], 'FontWeight','Bold');
        ylabel(Ydata, 'FontWeight','Bold');
    case 'RMSE'
        Fields = fieldnames(SimRndResults.RMSE);
        for ii = 1:length(Fields)
            dat(ii) = SimRndResults.RMSE.(Fields{ii});
        end
        bar(diag(dat),'stacked');
        set(gca,'Xtick',1:5,'XTickLabel', Fields);
        legend(Fields);
        xlabel('Fitted parameters', 'FontWeight','Bold');
        ylabel('Root Mean Squared Error', 'FontWeight','Bold');
    case 'NRMSE'
        Fields = fieldnames(SimRndResults.NRMSE);
        for ii = 1:length(Fields)
            dat(ii) = SimRndResults.NRMSE.(Fields{ii});
        end
        bar(diag(dat),'stacked');
        set(gca,'Xtick',1:5,'XTickLabel', Fields);
        legend(Fields);
        xlabel('Fitted parameters', 'FontWeight','Bold');
        ylabel('Normalized Root Mean Squared Error', 'FontWeight','Bold');
    case 'MPE'
        Fields = fieldnames(SimRndResults.MPE);
        for ii = 1:length(Fields)
            dat(ii) = SimRndResults.MPE.(Fields{ii});
        end
        bar(diag(dat),'stacked');
        set(gca,'Xtick',1:5,'XTickLabel', Fields);
        legend(Fields);
        xlabel('Fitted parameters', 'FontWeight','Bold');
        ylabel('Mean Percentage Error', 'FontWeight','Bold');
end