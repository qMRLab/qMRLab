function plotMP2RAGEproperties(MP2RAGE)

% define signal and noise function as in the paper
Signalres   = @(x1,x2) x1.*x2./((x2.^2+x1.^2));
noiseres   = @(x1,x2) ((x2.^2-x1.^2).^2 ./(x2.^2+x1.^2).^3 ).^(0.5);
alldata=1;

if ~isfield(MP2RAGE,'B0')
    T1WM=1.1;
    T1GM=1.85;
    T1CSF=3.5;
    B1range=0.6:0.2:1.4;

else
    if MP2RAGE.B0==3
        T1WM=0.85;
        T1GM=1.35;
        T1CSF=2.8;
        B1range=0.8:0.1:1.2;
    else
        % examples of T1 values at 7T
        T1WM=1.1;
        T1GM=1.85;
        T1CSF=3.9;
        B1range=0.6:0.2:1.4;
    end;
end;

hold off
% Contrast=0;
k=0;
for B1=B1range
    k=k+1;
    %     keyboard
    [MP2RAGEamp T1vector IntensityBeforeComb]=MP2RAGE_lookuptable(2,MP2RAGE.TR,MP2RAGE.TIs,B1*MP2RAGE.FlipDegrees,MP2RAGE.NZslices,MP2RAGE.TRFLASH,'normal',[],1);
    plot(MP2RAGEamp,T1vector,'color',[0.5 0.5 0.5]*B1,'Linewidth',2)
    hold on
    [temp, posWM ]=min(abs(T1WM - T1vector));
    [temp, posGM ]=min(abs(T1GM - T1vector));
    [temp, posCSF]=min(abs(T1CSF- T1vector));
% keyboard
    Signal=Signalres(IntensityBeforeComb([posWM,posGM,posCSF],1),IntensityBeforeComb([posWM,posGM,posCSF],2));
    noise=noiseres(IntensityBeforeComb([posWM,posGM,posCSF],1),IntensityBeforeComb([posWM,posGM,posCSF],2));
%     Contrast = Contrast + sum((Signal(2:end)-Signal(1:(end-1)))./sqrt(noise(2:end).^2+noise(1:(end-1)).^2))./sqrt(MP2RAGE.TR);
    Contrast{k} = num2str(1000 * sum((Signal(2:end)-Signal(1:(end-1)))./sqrt(noise(2:end).^2+noise(1:(end-1)).^2))./sqrt(MP2RAGE.TR));
    legendcell{k} = ['B1= ',num2str(B1)];

end
% legend('B1=0.6','B1=0.8','B1=1','B1=1.2','B1=1.4')
legend(legendcell)
% examples of T1 values at 3T
plot([-0.5 0.5],[T1CSF T1CSF;T1GM T1GM;T1WM T1WM]','Linewidth',2)
text(0.35,T1WM,'White Matter')
text(0.35,T1GM,'Grey Matter')
% text(-0.3,(T1CSF+T1GM)/2,['Contrast over B1 range = ',num2str(round(1000*Contrast))])
text(-0.3,(T1CSF+T1GM)/2,['Contrast over B1 range' ])
text(0,(T1CSF+T1GM)/2,Contrast)


ylabel('T1');
xlabel('MP2RAGE');



