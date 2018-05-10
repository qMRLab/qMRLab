function g = scd_display_qspacedata(data,scheme,bvalue,Marker,Linestyle,color,noise)
% scd_display_qspacedata(data,scheme)
% data: vector OR NxM matrix. N: number of measurement (=size(scheme,1)). M: number of
%      observation (for error bars).
% EXAMPLE:
%       SCD_DISPLAY_QSPACEDATA(Smodel,Ax.scheme)
%       SCD_DISPLAY_QSPACEDATA(Smodel,Ax.scheme,0,'x','-')


if ~exist('Marker','var'), Marker='x'; end
if ~exist('Linestyle','var'), Linestyle='none'; end
if ~exist('bvalue','var'), bvalue=0; end

gyro = 42.57; % kHz/mT
q = gyro*scheme(:,4).*scheme(:,6); % um-1

[q,I] = sort(q);
data = data(I); scheme = scheme(I,:);


seq=unique(scheme(:,9)); ND=length(seq);
if ~exist('color','var')
    color=jet(ND);
end

for iD=1:ND
    seqiD=find(scheme(:,9)==seq(iD));
    
    datavoxel=mean(squeeze(data),2);
    
    if bvalue
        g(iD)=plot(scd_scheme2bvecsbvals(scheme(seqiD,:)),datavoxel(seqiD),'LineStyle',Linestyle, 'Marker',Marker,'Color',color(min(iD,end),:),'LineWidth',2);
    else
        g(iD)=plot(q(seqiD),datavoxel(seqiD),'LineStyle',Linestyle, 'Marker',Marker,'Color',color(min(iD,end),:),'LineWidth',2);
    end
    hold on
    
    set(g(iD),'DisplayName',['G_{max}=' num2str(max(scheme(seqiD,4))*1e6,'%.0f') 'mT/m \Delta=' num2str(mean(scheme(seqiD,5)),'%.0f') 'ms \delta=' num2str(mean(scheme(seqiD,6)),'%.0f') 'ms TE=' num2str(mean(scheme(seqiD,7)),'%.0f') 'ms']);
    
    
    if exist('noise','var')==1
        
        h(iD)=errorbar(q(seqiD),datavoxel(seqiD),noise(seqiD), 'xr', 'Color', color);
    elseif size(data,2)>1
        data_stdvoxel=std(data,0,2);
        h(iD)=errorbar(q(seqiD),datavoxel(seqiD),data_stdvoxel(seqiD), 'xr', 'Color', color);
        %         figure(3)
        %         d(iD)=plot(q(seqiD),data_stdvoxel(seqiD),'LineStyle','none', 'Marker','x','Color',color,'LineWidth',2);
        %         hold on
    end
    if exist('h','var')==1
        % don't display data legend
        if ~moxunit_util_platform_is_octave
            hAnnotation = get(h(iD),'Annotation');
            hLegendEntry = get(hAnnotation','LegendInformation');
            set(hLegendEntry,'IconDisplayStyle','off');
        end
    end
end

if bvalue
    xlabel('bvalue','FontSize',15); 
else
    xlabel('q (um-1)','FontSize',15); 
end

ylabel('Signal (%b0)','FontSize',15);


if ~moxunit_util_platform_is_octave
    lgd = legend('show','Location','Best');
    set(lgd,'FontSize',8);
end
%ylim([0 1.2])
grid on, box off

hold off

% Add legend about linestyle
switch Linestyle
    case 'none'
        switch Marker
            case 'o'
                txt = [Marker ' = simulated data'];
                pos = [0.2, 0.97];
            case 'x'
                txt = [Marker ' = noisy simulated data'];
                pos = [0.5, 0.97];
        end
    otherwise
        txt = [Linestyle ' = fit'];
        pos = [0.8, 0.97];
end
t = text(pos(1),pos(2),txt,'Units','normalized');
set(t,'FontSize',10);
set(t,'BackgroundColor',[0.9  0.9 0.9]);

end
