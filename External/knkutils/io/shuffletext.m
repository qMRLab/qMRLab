function shuffletext(filein,fileout,mode)

% function shuffletext(filein,fileout,mode)
%
% <filein> is a text file
% <fileout> is a location to write to
% <mode> (optional) is
%   0 means normal (treat every line as distinct)
%   1 means grouped (only shuffle blocks of lines (blocks are separated by blank lines))
%   Default: 0.
%
% example:
% savetext('test.txt',{'a' 'b' 'c'});
% shuffletext('test.txt','testshuffle.txt');

% input
if ~exist('mode','var') || isempty(mode)
  mode = 0;
end

% read the file
a = loadtext(filein);

% deal with grouped case
switch mode
case 0
  newlist = a;  % do nothing
case 1
  newlist = {};
  cur = '';
  for p=1:length(a)
    if isequal(a{p},'')
      newlist{end+1} = [cur];
      cur = '';
    else
      cur = [cur a{p} sprintf('\n')];
    end
  end
  newlist{end+1} = [cur];  % deal with the last one
end

% permute
newlist = permutedim(newlist);

% write it out
savetext(fileout,newlist);
