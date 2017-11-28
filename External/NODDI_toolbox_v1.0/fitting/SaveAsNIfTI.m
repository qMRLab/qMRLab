function SaveAsNIfTI(data, target, output)

% function SaveAsNIfTI(data, nifti)
%
% Input:
%
% data: the data array to be saved to disk
%
% target: the NIfTI object specifying the target volume specification
%
% output: the filename for the output NIfTI file
%

% following the example in
% http://niftilib.sourceforge.net/mat_api_html/README.txt
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

dat = file_array;
dat.fname = output;
dat.dim = target.dim;
dat.dtype = 'FLOAT64-LE';
dat.offset = ceil(348/8)*8;

N = nifti;
N.dat = dat;
N.mat = target.mat;
N.mat_intent = target.mat_intent;
N.mat0 = target.mat0;
N.mat0_intent = target.mat0_intent;

create(N);

N.dat(:,:,:,:) = data;
