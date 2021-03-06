aa = json2struct('xnames_units_BIDS_mappings.json');
xx = fieldnames(aa);
lut = [];
for ii=1:length(xx)
    disp(xx{ii});
    parent = cellstr(repmat(xx{ii},[length(aa.(xx{ii}).xnames) 1]));
    xnames = cellstr(aa.(xx{ii}).xnames)';
    suffix = cellstr(aa.(xx{ii}).suffixBIDS)';
    isBIDS = cell2mat(aa.(xx{ii}).isOfficialBIDS)';
    folderBIDS = cellstr(aa.(xx{ii}).folderBIDS)';
    cur_lut = table(parent,xnames,suffix,isBIDS,folderBIDS,'VariableNames',{'parent','xnames','suffixBIDS','isBIDS','folderBIDS'});
    lut = [lut;cur_lut];
end