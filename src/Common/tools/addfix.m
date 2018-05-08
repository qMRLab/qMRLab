function st = addfix( st, x, fx )
% x2 = addfix( st, x, fx )
    st(~fx) = x;
end
