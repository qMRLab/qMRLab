function str = genvarname_v2(str)
str = strrep(str,'##','');
str = strrep(str,'**','');
str = strrep(str,'#','N');
str = strrep(str,' ','');
str = strrep(str,'=','');
str = strrep(str,'-','');
str = strrep(str,'(','');
str = strrep(str,')','');
str = strrep(str,'/','');
str = strrep(str,'*','');
str = strrep(str,'�','e');






