function output = checkanteriorver(version,ub)
if version(1)<ub(1) || (version(1)==ub(1) && (version(2)<ub(2) || (version(2)==ub(2) && version(3)<=ub(3))))
    output = true;
else
    output = false;
end
