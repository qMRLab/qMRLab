function cdmfile(file)
    [pathstr,fname,ext]=fileparts(which(file));
    cd (pathstr);
end