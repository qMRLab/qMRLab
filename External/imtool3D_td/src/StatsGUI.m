% STATS Table
function f = StatsGUI(I,Maskall, fields, Color)
if ~exist('Color','var'), Color = jet(double(max(1+Maskall(:)))); end
if iscell(I)
    Nvol = length(I); 
else
    Nvol = size(I,5);
end
if ~exist('fields','var') || isempty(fields)
    fields = cellfun(@(x) ['vol #' x],strsplit(num2str(Nvol:-1:1)),'uni',0); 
end

values = unique(Maskall(Maskall>0))';

yprev = 1;
if isempty(values), values = 0; end
f=figure('Position', [100 100 700 400], 'Name', 'Statistics','MenuBar','none','ToolBar','none');
for Selected = values
    Mask = Maskall==Selected;
    Stats = cell(length(fields),7);
    for iii=1:length(fields)
        if iscell(I)
            datiii = nanmean(I{length(fields)+1-iii},4); % average 4D data along time
        else
            datiii = nanmean(I(:,:,:,:,length(fields)+1-iii),4);
        end
        datiii = datiii(Mask);
        Stats{iii,1} = mean(datiii);
        Stats{iii,2} = median(datiii);
        Stats{iii,3} = std(datiii);
        Stats{iii,4} = min(datiii);
        Stats{iii,5} = max(datiii);
        [Stats{iii,6}, Stats{iii,7}] = range_outlier(datiii,0);
        Stats{iii,8} = Stats{iii,7} - Stats{iii,6};
    end
    
    uitable(f,'Units','normalized','Position',[0,yprev - 1/length(values),1,1/length(values)],'Data',Stats,...
              'ColumnName',{'mean', 'median', 'std','min','max','1st quartile', '3rd quartile', 'Interquartile Range (IQR)'},...
              'ColumnFormat',{'numeric', 'numeric', 'numeric','numeric','numeric','numeric','numeric','numeric'},...
              'ColumnEditable',[false false false false false false false false false],...
              'RowName',fields','BackgroundColor',Color(Selected+1,:).*[.4 .4 .4]+1-[.4 .4 .4]);
    yprev = yprev - 1/length(values);
end
