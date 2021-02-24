function g = scd_display_qspacedata3D(data,scheme,fibredir,Marker,Linestyle,color,noise)
% scd_display_qspacedata(data,scheme,fibredir)
% data: vector OR NxM matrix. N: number of measurement (=size(scheme,1)). M: number of
%      observation (for error bars).
% EXAMPLE:
%       SCD_DISPLAY_QSPACEDATA(Smodel,Ax.scheme)
%       SCD_DISPLAY_QSPACEDATA(Smodel,Ax.scheme,0,'x','-')


if ~exist('Marker','var'), Marker='x'; end
if ~exist('Linestyle','var'), Linestyle='none'; end


Gparr=scheme(:,1:3)*fibredir(:);
absc = Gparr;
[absc,II] = sort(absc); scheme = scheme(II,:); data = data(II);
bval = scd_scheme_bvalue(scheme);

if size(scheme,2)<9
    % Find different shells
    list_G=unique(round(scheme(:,[4 5 6 7])*1e8)/1e8,'rows');
    nnn = size(list_G,1);
    for j = 1 : nnn
        for i = 1 : size(scheme,1)
            if  round(scheme(i,[4 5 6 7])*1e8)/1e8 == list_G(j,:)
                scheme(i,9) = j;
            end
        end
    end
end


seq=unique(scheme(:,9)); ND=length(seq);
if ~exist('color','var')
    color=jet(ND);
end

for iD=1:ND
    seqiD=find(scheme(:,9)==seq(iD));
    
    datavoxel=mean(squeeze(data),2);
    
    g(iD)=plot(absc(seqiD,:),datavoxel(seqiD),'LineStyle',Linestyle, 'Marker',Marker,'Color',color(min(iD,end),:),'LineWidth',2);
    
    if ~moxunit_util_platform_is_octave
        hold on
        set(g(iD),'DisplayName',['bvalue=' num2str(max(bval(seqiD))*1e3,'%.0f') 's/mm^2 G=' num2str(max(scheme(seqiD,4))*1e6,'%.0f') 'mT/m \Delta=' num2str(mean(scheme(seqiD,5)),'%.0f') 'ms \delta=' num2str(mean(scheme(seqiD,6)),'%.0f') 'ms TE=' num2str(mean(scheme(seqiD,7)),'%.0f') 'ms']);
    end
    
    if exist('noise','var')==1
        
        h(iD)=errorbar(absc(seqiD),datavoxel(seqiD),noise(seqiD), 'xr', 'Color', color);
    elseif size(data,2)>1
        data_stdvoxel=std(data,0,2);
        h(iD)=errorbar(absc(seqiD),datavoxel(seqiD),data_stdvoxel(seqiD), 'xr', 'Color', color);
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

if ~moxunit_util_platform_is_octave
    xlabel('G_{//}/|G|','FontSize',15); 
    ylabel('Signal','FontSize',15);
    legend('show','Location','Best')
    set(gca,'FontSize',15)
    %ylim([0 1.2])
    grid on, box off
    hold off
end


% Add legend about linestyle
switch Linestyle
    case 'none'
        switch Marker
            case 'o'
                txt = [Marker ' = simulated data'];
                pos = [0.25, 0.97];
            case 'x'
                txt = [Marker ' = noisy simulated data'];
                pos = [0.5, 0.97];
        end
    otherwise
        txt = [Linestyle ' = fit'];
        pos = [0.75, 0.97];
end
t = text(pos(1),pos(2),txt,'Units','normalized');

if ~moxunit_util_platform_is_octave
    set(t,'FontSize',10);
    set(t,'BackgroundColor',[0.9  0.9 0.9]);
end

end
