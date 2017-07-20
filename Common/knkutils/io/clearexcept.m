function clearexcept(vars)

% function clearexcept(vars)
%
% <vars> is a variable name or a cell vector of variable names
%
% clear all variables except for the ones in <vars>.
% be aware that we achieve this by writing the variables
% in <vars> to a temporary file.
%
% example:
% x = 1; y = 2; z = 3;
% clearexcept('x');
% whos

% input
if ~iscell(vars)
  vars = {vars};
end

% figure out a temporary file
tempfile0 = [tempname '.mat'];

% do it
temp = cell2str(vars);
cmd = sprintf('save ''%s'' %s; clear all; load ''%s'';',tempfile0,temp(3:end-2),tempfile0);
evalin('caller',cmd);
