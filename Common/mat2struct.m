function xs=mat2struct(x,fields)
for ix=1:length(x)
    xs.(fields{ix}) = x(ix);
end