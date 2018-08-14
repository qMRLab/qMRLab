function SimVaryPlot(SimVaryResults,Xaxis,Yaxis)

Xmin =  SimVaryResults.(Xaxis).x(1)  ;
Xmax =  SimVaryResults.(Xaxis).x(end);
Xmin = Xmin - (Xmax-Xmin)/50;
Xmax = Xmax + (Xmax-Xmin)/50;
X    =  SimVaryResults.(Xaxis).x;
% Pad if canceled
Y = nan(size(X));
E = nan(size(X));
Y(1:length(SimVaryResults.(Xaxis).(Yaxis).mean))    =  SimVaryResults.(Xaxis).(Yaxis).mean;
E(1:length(SimVaryResults.(Xaxis).(Yaxis).std))    =  SimVaryResults.(Xaxis).(Yaxis).std;


if (strcmp(Xaxis,Yaxis))
    plot([Xmin Xmax], [Xmin Xmax], 'k-'); hold on;
else
    if ~isempty(SimVaryResults.(Xaxis).(Yaxis).GroundTruth)
        plot([Xmin Xmax],[SimVaryResults.(Xaxis).(Yaxis).GroundTruth SimVaryResults.(Xaxis).(Yaxis).GroundTruth], 'k-','DisplayName','GroundTruth');
        hold on
    end
end
set(gca,'FontUnit','normalized')
he = errorbar(X, Y, E);
set(he,'DisplayName','Mean +/- Std')
xlabel(sprintf('Input %s',  Xaxis), 'FontWeight', 'Bold');
ylabel(sprintf('Fitted %s', Yaxis), 'FontWeight', 'Bold');
xlim([Xmin Xmax]);
hold off;
grid('on');
