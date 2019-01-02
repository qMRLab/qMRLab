function Origin = get_svds_origin

Origin = struct();
Origin.operationSystem = computer; 
Origin.softwareName = 'qMRLab';
Origin.softwareVersion = qMRLabVer(); 
if moxunit_util_platform_is_octave
Origin.platform = 'Octave';
else
Origin.platform = 'MATLAB';    
end
Origin.platformVersion = version;
Origin.date = date; 

end