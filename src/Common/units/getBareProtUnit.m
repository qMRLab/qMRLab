function out = getBareProtUnit(in,selection)
% Protocols fields are appended by the unit sybols if applicable.
% UnitBIDSMappings fieldnames are defined using the bare Prot fieldnames. 
% Hence, to access them, the symbol should be dropped TI(*)-->TI.
% Another use case is inferring the symbol.
    
    if iscell(in)
        in = cell2mat(in);
    end
    
    prLoc = strfind(in,'(');
    if ~isempty(prLoc)
        switch selection
            case 'symbol'
            out = cellstr(in(prLoc:end));    
            case 'fieldname'
            out = cellstr(in(1:prLoc-1));
        end

    else
        switch selection
            case 'symbol'
            out = [];    
            case 'fieldname'
            out = cellstr(in);
        end
    end

end