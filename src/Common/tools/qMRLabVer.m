function ver = qMRLabVer
% qMRLabVer  Display qMRLab version

versionfile='version.txt';
fid = fopen(versionfile,'r');
s = fgetl(fid);
fclose(fid);
if nargout
    ver = sscanf(s,'v%i.%i.%i')';
else
    disp(['qMRLab version: ' s])
end