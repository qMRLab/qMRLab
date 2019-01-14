classdef mp2rage < AbstractModel
% new_model_name: One-line explanation of model. <br>
%<br>
% Assumptions:
%	(1)   ?.
%	(#)   ?.
%
% Inputs:
%	inputName1		?.
%	inputName#		?.
%
% Outputs:
%	outputName1		?.
%	outputName#		?.
%
% Protocol:
%	protField1		?.
%	protField#		?.
%
% Options: <br>
%	OptionField1 <br>
%		?op1?		?.
%		?op#?		?.
%	OptionField# <br>
%		?op1?		?.
%		?op#??		?.
%
% Author: Your_name Your_Surname (Year)
%
% References:
% Please cite the following if you use this module:
% reference_to_the_paper

properties (Hidden=true)
    onlineData_url = 'https://osf.io/8x2c9/download?version=1';
end

properties
   MRIinputs = {'MP2RAGEData','B1map','Mask'};
   xnames = {'T1', 'M0'};
   voxelwise = 1;
   Prot  = struct('T2Data',struct('Format',{{'TE(ms)'  'DropFirstEcho'  'OffsetTerm'}},...
                                         'Mat', [10 20 30],'DropFirstEcho',true, 'OffsetTerm', true));
   st           = [0 0]; % starting point
   lb           = [0 0]; % lower bound
   ub           = [1 1]; % upper bound
   
   buttons = {}; 
   options = struct(); 
end

end