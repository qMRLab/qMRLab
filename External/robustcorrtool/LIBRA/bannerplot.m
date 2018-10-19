function bannerplot(usedvars,separationstep,nobs,class,heights,objectorder)

%BANNERPLOT creates a banner for the output of the clustering algorithms
%agnes, diana or mona.
%
% I/O: bannerplot(out)
%
% This function is part of LIBRA: the Matlab Library for Robust Analysis,
% available at:
%              http://wis.kuleuven.be/stat/robust.html
%
%Note: execute the following command if you have run the bannerplot at the
%commandline to ensure the axes are reset to their original colours for the
%next plot on the same figure window
% > whitebg([1 1 1])
%
% Last update: 12/02/2009 by S.Verboven

switch class
    case 'MONA'
        Y=separationstep;
        stepmax=max(Y)+1;
        Y(Y==0)=stepmax;
        barh(fliplr(Y),1)
        set(gcf, 'Name','Banner','numbertitle','off')
        whitebg([1 1 1])
        xlabel('Separation Step')
        xticks=0:stepmax;
        set(gca,'XTick',xticks,'XTickLabel',xticks,'xcolor','k');
        axis([0,stepmax,0.5,nobs-0.5])
        Uvar=num2str(usedvars);
        Uvar=fliplr(Uvar);
        for k=1:nobs-1
            Uvar2(k)=Uvar(k+((k-1)*2));
        end
        for i=1:(usedvars-1)
            if Y(i)<stepmax
                text(Y(i)+0.3,i,Uvar2(i))
            end
        end
    case 'AGNES'
        bprops=barh(fliplr(heights),1,'w','edgecolor','w');
        fig = ancestor(bprops,'figure');
        set(fig, 'Name','Banner','numbertitle','off')
        set(gca(fig),'color',[0.4 0.5 0.75])
        xlabel('Height','color','k')
        set(gca,'YAxisLocation','right','xcolor','k')
        axis([min([heights 0]), max([heights 0]), 0.45, nobs-0.45])
    case 'DIANA'
        bprops=barh(fliplr(heights),1,'w','edgecolor','w');
        fig = ancestor(bprops,'figure');
        set(fig, 'Name','Banner','numbertitle','off')
        set(gca(fig),'color',[0.4 0.5 0.75])
        xlabel('Height','color','k')
        set(gca,'XDir','reverse','xcolor','k');
        axis([min([heights 0]), max([heights 0]), 0.45, nobs-0.45])
end
set(gca,'XColor','k','YColor','k')
yticks=0.5:nobs;
set(gca,'YTick',yticks,'YTickLabel',fliplr(objectorder),'ycolor','k');
title(['Banner obtained with ', class,' clustering'],'color','k')
ylabel('Objects','color','k')


