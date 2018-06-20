function xs=mat2struct(x,fields)
% x = mat2struct(Model.st,Model.xnames)
if isnumeric(x)
    for ix=1:length(x)
        xs.(fields{ix}) = x(ix);
    end
elseif isstruct(x)
    xs = x;
end