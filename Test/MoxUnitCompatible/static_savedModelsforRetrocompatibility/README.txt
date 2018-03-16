Please do not make uncoordinated changes on .qmrlab.mat files in this folder. 

These files are used for testing compatibility of the struct fields of
constructed objects and that of saved here. 

If some changes are agreed to be made on the class definitions (global or individual), then:
1- Increment version in qMRLab/version.txt
2- please update Patch Method of the corresponding Model.

Last updated: Nov 28 2017 by Agah Karakuzu 

Files can be generated using:
>> Model = denoising_mppca; % replace 'denoising_mppca' with your Model Name
>> Model.saveObj