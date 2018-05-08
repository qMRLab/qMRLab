function Prot = ProtLoad(fullfilepath)
[~,~,ext] = fileparts(fullfilepath);
filterindex = find(cellfun(@isempty,strfind({'*.mat';'*.xls;*.xlsx';'*.txt;*.scheme'},ext))==0);
switch filterindex
    case 1
        Prot = load(fullfilepath);
        fields = (fieldnames(Prot));
        Prot = Prot.(fields{1});
    case 2
        Prot = xlsread(fullfilepath);
    case 3
        Prot = txt2mat(fullfilepath);
end
