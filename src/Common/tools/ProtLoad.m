function Prot = ProtLoad(fullfilepath)
[~,~,ext] = fileparts(fullfilepath);
filterindex = find(cellfun(@isempty,strfind({'*.mat';'*.xls;*.xlsx';'*.txt;*.scheme';'*.bvec'},ext))==0);
switch filterindex
    case 1
        Prot = load(fullfilepath);
        fields = (fieldnames(Prot));
        Prot = Prot.(fields{1});
    case 2
        Prot = xlsread(fullfilepath);
    case 3
        Prot = txt2mat(fullfilepath);
    case 4 % manage bvec/bvals
        bvecfile = fullfilepath;
        [FileName,PathName] = uigetfile({'*.bval;*.txt'},'Load bval',strrep(fullfilepath,'.bvec','.bval'));
        if PathName == 0, Prot=0; return; end
        bvalfile = fullfile(PathName,FileName);
        Model = getappdata(0,'Model');
        if ismember(length(Model.Prot.DiffusionData.Format), [7 8])
            fprintf(['Assuming max gradient of 40mT/m...\n'])
            Prot = scd_schemefile_FSLconvert(bvalfile, bvecfile, 40);
            Prot(:,4) = Prot(:,4)*1e3;
            Prot(:,5:end) = Prot(:,5:end)*1e-3;
        else
            bvec = txt2mat(bvecfile); bvec = bvec';
            bval = txt2mat(bvalfile); bval = bval(:);
            Prot = cat(2,bvec,bval);            
        end
        
end
