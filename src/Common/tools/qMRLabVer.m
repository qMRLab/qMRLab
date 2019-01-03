function ver = qMRLabVer
% qMRLabVer  Display qMRLab version

if moxunit_util_platform_is_octave
    warning ('off', 'Octave:data-file-in-path') 
end

versionfile='version.txt';
fid = fopen(versionfile,'r');
s = fgetl(fid);
fclose(fid);
if nargout
    ver = sscanf(s,'v%i.%i.%i')';
else
    disp(['qMRLab version: ' s])
end