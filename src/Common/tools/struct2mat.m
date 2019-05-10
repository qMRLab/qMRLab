function x=struct2mat(xs,fields)         
if isstruct(xs) % if x is a structure, convert to vector
    for ix = 1:length(fields)
        xtmp(ix) = xs.(fields{ix});
    end
    x = xtmp;
elseif isnumeric(xs)
    x = xs;
end
