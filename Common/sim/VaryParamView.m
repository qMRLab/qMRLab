function VaryParamView(SensResults, FieldsX, FieldsY)

% -------------------------------------------------------------------------
% VaryParamView(SensResults, FieldsX, FieldsY)
% Plot sensitivity analysis results
%
% FieldsX/Y are cells with input/fitted fieldnames to be plotted
% If not specified, show all
% -------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% -------------------------------------------------------------------------

% PLOT RESULTS
Param     =  SensResults.Sim.Param;

if (~exist('FieldsX','var') || isempty(FieldsX))
    FieldsX = fieldnames(SensResults.SimVaryResults);
end

if (~exist('FieldsY','var') || isempty(FieldsY))
    FieldsY = SensResults.FitOpt.names;
end

nX = length(FieldsX);
nY = length(FieldsY);

figure();
x = 1;
for i = 1:nX
    for j = 1:nY
        subplot(nX,nY,x);
        Xaxis = FieldsX{i};
        Yaxis = FieldsY{j};
        
        Xmin =  SensResults.SimVaryResults.(Xaxis).x(1)   - SensResults.SimVaryResults.(Xaxis).step;
        Xmax =  SensResults.SimVaryResults.(Xaxis).x(end) + SensResults.SimVaryResults.(Xaxis).step;
        X1    =  SensResults.SimVaryResults.(Xaxis).x;
        Y1    =  SensResults.SimVaryResults.(Xaxis).(Yaxis).mean;
        E1    =  SensResults.SimVaryResults.(Xaxis).(Yaxis).std;
        
        cla;
        hold on;
        if (strcmp(Xaxis,Yaxis))
            plot([Xmin Xmax], [Xmin Xmax], 'k-');
        elseif (any(strcmp(Yaxis,fieldnames(Param))))
            plot([Xmin Xmax],[Param.(Yaxis) Param.(Yaxis)], 'k-');
        end
        errorbar(X1, Y1, E1, 'bo');
        
        xlabel(sprintf('Input %s',  Xaxis), 'FontWeight', 'Bold');
        ylabel(sprintf('Fitted %s', Yaxis), 'FontWeight', 'Bold');
        xlim([Xmin Xmax]);
        hold off;
        x = x+1;
    end
end
subplot(nX,nY,1);
legend('true','Fitted');


