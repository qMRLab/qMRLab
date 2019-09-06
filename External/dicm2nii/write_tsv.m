function write_tsv(id,tsvfile,varargin)
% write_tsv     write a tsv (tabulated-separated) file
%               if tsvfile already exists, replace value at the line defined
%                 by an id (first column) or add a new line
%
% write_tsv(id,tsvfile,varargin)
% Example:
%   write_tsv('Pierre','stats.tsv','age',50)
%   write_tsv('Jean',  'stats.tsv','age',20)
%   write_tsv('Jean',  'stats.tsv','height',180)

if iscell(tsvfile), tsvfile = tsvfile{1}; end
if exist(tsvfile,'file') % read already existing tsvfile
    T = readtable(tsvfile,'FileType','text','Delimiter','\t','Format',repmat('%s',[1,length(varargin)/2+1]));
end
varargin(1:2:end) = cellfun(@genvarname,varargin(1:2:end),'uni',0);
if exist(tsvfile,'file') && ~isempty(T) % append to already existing tsvfile
    ind = find(strcmp(table2cell(T(:,1)),id),1);
    if isempty(ind)
        ind = size(T,1)+1;
        T.(T.Properties.VariableNames{1}){end+1,1} = char(string(id));
    end
    
    for ii=1:2:length(varargin)
        if ismember(varargin{ii},T.Properties.VariableNames)
            
        else
            if isnumeric(varargin{ii+1})
                T.(varargin{ii}) = nan(size(T,1),1);
            else
                T.(varargin{ii}) = cell(size(T,1),1);
            end
        end
        if iscell(T.(varargin{ii}))
            T.(varargin{ii}){ind} = varargin{ii+1};
        else
            T.(varargin{ii})(ind) = varargin{ii+1};
        end
    end

else % write new tsvfile
    T=table;
    T(end+1,:) = {char(string(id)), varargin{2:2:end}};
    if isempty(inputname(1))
        idName = 'id';
    else
        idName = inputname(1);
    end
    T.Properties.VariableNames = {idName varargin{1:2:end}};
end
writetable(T,tsvfile,'Delimiter','\t','FileType','text')
