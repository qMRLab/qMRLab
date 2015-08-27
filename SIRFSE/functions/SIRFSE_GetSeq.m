function [Ti,Td] = SIRFSE_GetSeq(ti,td)

Ti = ti;
Td = td;

if size(Ti,1) == 1;  Ti = Ti';  end

if size(Td,1) == 1;  Td = Td';  end

if length(Td) == 1;
    Td = Td*ones(length(Ti),1);
end

end
