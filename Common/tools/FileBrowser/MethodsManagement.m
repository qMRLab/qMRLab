% Methods File Management
% P. Beliveau 2017
% This file writes the default input file names that will be displayed in
% the file browser window.
% 
% TO ADD METHODS: add a method at the end of the file "MethodsFileList.txt'
%                   and follow its file format


bSSFP = {'bSSFP', 'Mask', 'MTdata', 'R1map'};
SIRFSE = {'SIRFSE','Mask', 'MTdata'};
SPGR = {'SPGR','Mask', 'MTdata', 'R1map', 'B1map','B0map'};
MTSAT = {'MTSAT','Mask', 'MT', 'PD', 'T1'};

fileID = fopen('MethodsFileList.txt', 'w');

formatSpec = '%s %s %s %s \n'; 
fprintf(fileID, formatSpec, bSSFP{1, :});

formatSpec = '%s %s %s \n';
fprintf(fileID, formatSpec, SIRFSE{1, :});

formatSpec = '%s %s %s %s %s %s \n';
fprintf(fileID, formatSpec, SPGR{1, :});

formatSpec = '%s %s %s %s %s \n';
fprintf(fileID, formatSpec, MTSAT{1, :});

fclose(fileID);





% 
% formatSpec = 'X is %4.2f meters or %8.3f mm\n';
% fprintf(formatSpec,A1,A2)
% 
% x = 0:.1:1;
% A = [x; exp(x)];
% 
% fileID = fopen('exp.txt','w');
% fprintf(fileID,'%6s %12s\n','x','exp(x)');
% fprintf(fileID,'%6.2f %12.8f\n',A);
% fclose(fileID);


