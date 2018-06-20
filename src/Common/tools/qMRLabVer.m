function ver = qMRLabVer
%%
versionfile='version.txt';
fid = fopen(versionfile,'r');
s = fgetl(fid);
fclose(fid);
ver = sscanf(s,'v%i.%i.%i')';