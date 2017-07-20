function saveexcept(file,vars,mode)

% function saveexcept(file,vars,mode)
%
% <file> is a string referring to a .mat file
% <vars> is a variable name or a cell vector of variable names to NOT save
% <mode> (optional) is
%   0 means do the normal thing (save variables except <vars>)
%   1 means do the opposite     (save variables listed in <vars>)
%   Default: 0.
%
% save all variables that exist in the caller to <file>, 
% except variables named by <vars>.
%
% example:
% x = 1; y = 2; z = 3;
% saveexcept('temp.mat','z');
% a = load('temp.mat')

% input
if ~iscell(vars)
  vars = {vars};
end
if ~exist('mode','var') || isempty(mode)
  mode = 0;
end

% figure out variable list
switch mode
case 0

  % figure out variable names
  varlist = evalin('caller','whos');
  varlist = cat(2,{varlist.name});

  % exclude the ones we don't want
  ok = cellfun(@(x) ~ismember(x,vars),varlist);
  varlist = varlist(ok);

case 1

  % the user specified what to save
  varlist = vars;

end

% save the data
temp = cell2str(varlist);
cmd = sprintf('save ''%s'' %s;',file,temp(3:end-2));
evalin('caller',cmd);
