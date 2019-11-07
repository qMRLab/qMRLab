function ind=findn(arr);

%FINDN   Find indices of nonzero elements.
%   I = FINDN(X) returns the indices of the vector X that are
%   non-zero. For example, I = FINDN(A>100), returns the indices
%   of A where A is greater than 100. See RELOP.
%  
%   This is the same as find but works for N-D matrices using 
%   ind2sub function
%
%   It does not return the vectors as the third output arguement 
%   as in FIND
%   
%   The returned I has the indices (in actual dimensions)
%
%   x(:,:,1)            x(:,:,2)            x(:,:,3)
%       = [ 1 2 3           =[11 12 13        =[21 22 23
%           4 5 6             14 15 16          24 25 26
%           7 8 9]            17 18 19]         27 28 29]
%
%   I=find(x==25) will return 23
%   but findn(x==25) will return 2,2,3
%   
%   Also see find, ind2sub

%   Loren Shure, Mathworks Inc. improved speed on previous version of findn
%   by Suresh Joel Mar 3, 2003

in=find(arr);
sz=size(arr);
if isempty(in), ind=[]; return; end;
[out{1:ndims(arr)}] = ind2sub(sz,in);
ind = cell2mat(out);