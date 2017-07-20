function f = stripext(x)

% function f = stripext(x)
%
% <x> is a string referring to a filename
%
% return <x> but with any filename extension stripped.
% be careful when using this function, as we assume that
% there is a dot (.) to be matched.
%
% example:
% isequal('test',stripext('test.txt'))

start = regexp(x,'\.[^\.]*$');  % match a dot and then zero or more non-dot characters
if isempty(start)
  f = x;
else
  f = x(1:start-1);
end
