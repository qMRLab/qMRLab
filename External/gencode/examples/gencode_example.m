%% GENERATE CODE FOR VARIABLES
% This document demonstrates the usage of GENCODE, GENCODE_RVALUE and
% GENCODE_SUBSTRUCT to show and modify the contents of complicated MATLAB
% variables.
%%
%% A TEST VARIABLE
% The variable x is a struct with two fields: f1 and f2. f1 is a cell array
% of arbitrary items.
x.f1        = {1 'somestring' false};
%% 
% f2 is a struct array with 2 members and fields f21, f22, f23. The fields
% in f2(1) hold different numeric types.
x.f2(1).f21 = diag([1 1 -Inf NaN]);
x.f2(1).f22 = speye(5);
x.f2(1).f23 = 17 * ones(5,6,2,'int8');
%%
% The fields in f2(2) hold a cell string array, a logical array and a
% (anonymous) function handle.
x.f2(2).f21 = {'string 1'; 'string 2'; 'A third string'};
x.f2(2).f22 = rand(5) > .5;
x.f2(2).f23 = @(x)mod(x,2);
%% GENERATE CODE FOR RIGHT HAND SIDE OF ASSIGNMENTS
% GENCODE uses GENCODE_RVALUE to generate code for the right hand side of
% assignments. This works for 
%
% * all scalar, vector, 2D data
% * cells with scalar, vector, 2D members
% * function handles
%
[str, sts] = gencode_rvalue(x.f1);
display(sts)
char(str)
%%
% x.f2(1).f23 is a 3D array, therefore GENCODE_RVALUE does not work here -
% sts is false
size(x.f2(1).f23)
[str, sts] = gencode_rvalue(x.f2(1).f23);
display(sts)
char(str)
%% GENERATE CODE FOR TEST VARIABLE
% The simplest way to invoke GENCODE is with just the variable as input
% argument. Code for arrays with more than 2 dimensions is split up into
% code for 2D subarrays.
% Code for sparse matrices is generated using three temporary variables
% tmpi, tmpj and tmps.
strx = gencode(x);
char(strx)
%%
% If the name of the variable should be different from the input variable
% name, GENCODE can be called with an alternative name. This can also be an
% struct reference (|y.a|) or cell entry (|y{2}|) or array index (|y(1)|).
stry = gencode(x,'y.a');
char(stry)
%% USE GENERATED CODE TO RECREATE VARIABLE
% The generated code can be used to recreate the variable:
clear x
eval(sprintf('%s\n', strx{:}))
display(x)
%%
% Usually, one would write the code to a file using a sequence of commands
% like this:
%
% <html>
% <pre class="codeinput">
% fid = fopen('test.m','w');
% fprintf(fid, '%s\n', strx{:});
% fclose(fid)
% </pre>
% </html>
%
% This file can then be modified to recreate new instances of x.
