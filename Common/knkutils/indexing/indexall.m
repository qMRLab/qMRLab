function f = indexall(numdims,dim,idx)

% function f = indexall(numdims,dim,idx)
% 
% <numdims> is the number of total dimensions
% <dim> is the dimension we care about
% <idx> are the indices corresponding to <dim>
%
% return a cell vector of length <numdims>
% like {':' ':' <idx>} where the location of
% <idx> is <dim>.
%
% example:
% indexall(3,2,1:3)

f = repmat({':'},1,numdims);
f{dim} = idx;
