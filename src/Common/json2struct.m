function out = json2struct(filename)

tmp = loadjson(filename);

if isstruct(tmp)

    out = tmp;

else

    str = cell2struct(tmp,'tmp');
    out = [str.tmp];

end

end 