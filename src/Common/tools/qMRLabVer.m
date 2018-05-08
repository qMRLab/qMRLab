function ver = qMRLabVer
%%
versionfile=fullfile(fileparts(which('qMRLab.m')),'version.txt');
fid = fopen(versionfile,'r');
s = fgetl(fid);
fclose(fid);
ver = sscanf(s,'v%i.%i.%i')';