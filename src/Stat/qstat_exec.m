% Create a qmrstat_correlation object for 3 maps. 
cor = qmrstat_correlation(1,3); 

% You can load a map by proviging an absolute path to a MATLAB or NIFTI
% file:

cor(1) = cor(1).loadMap('/Users/Agah/Desktop/NIST_Process/Data3/AVERAGE_nii/irT1.nii');
cor(2) = cor(2).loadMap('/Users/Agah/Desktop/NIST_Process/Data3/TEST_nii/irT1.nii');
cor(3) = cor(3).loadMap('/Users/Agah/Desktop/NIST_Process/Data3/RETEST_nii/irT1.nii');

cor(1).MapNames = {'irT1mean'};
cor(2).MapNames = {'irT1test'};
cor(3).MapNames = {'irT1retest'};

% Now, you need to set a mask for the qmrstat_correlation object.
% There is an assumption that maps uploaded to the cor(1), cor(2) and
% cor(3) are aligned. Correspondingly, mask is also assumed to be aligned.
% Therefore, you can load mask just once for the whole object: 

cor = cor.loadStatMask('/Users/Agah/Desktop/NIST_Process/Data3/LabelMask.nii');

% You may want to save static figures. Other options are 'osd' and 'off'. 

cor = cor.setStaticFigureOption('save');

% Now you will create a qmrstat object to perform statistical operations on
% the qmrstat_submodules (qmrstat_correlation in this case). 

qs = qmrstat; 

% Set an output folder for the module. 

qs = qs.setOutputDir('/Users/Agah/Desktop/NIST_Process/Data3/Outputs');

% Enable this option to do cool stuff.

qs = qs.setSVDS_On;

%qs = qs.runCorPearson(cor);
%qs = qs.runCorSpearman(cor);
%qs = qs.runCorConcordance(cor);
 qs = qs.runCorSkipped(cor);

qs.saveStaticFigures()
qs.saveSVDS();

%%




