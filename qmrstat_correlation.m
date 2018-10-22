classdef qmrstat_correlation < AbstractStat
% Correlation family
% ===============================================================
properties

VariableID
SignificanceLevel = 5/100;
FigureOption = 'osd';

end
% ===============================================================

methods

function obj = qmrstat_correlation(m,n)

  W = evalin('caller','whos');

  if nargin ~= 0

    % Row index identifies number of qmrstat_correlation objects
    % Column index identifies the number of correlation components included in
    % each qmrstat_correlation object.


    if (m >2 && n==1) || (m == 1 && n==1)
      error('Each qmrstat_object array should at least have two pairs.');
    end

    obj(m,n) = obj;

    for i = 1:m
      for j = 1:n
      obj(i,j).VariableID = [num2str(i) '::' num2str(j)];
      end
    end

  elseif nargin == 0 && ~(ismember('m',[W(:).name]) || ismember('m',[W(:).name]))

    obj = qmrstat_correlation(1,2);

  end

end

function obj = loadStatMask(obj,input)
  % This function assigns the StatMask property.
  % StatMask can be a labeled mask or a binary mask.
  %
  % loadStatMask method accepts following inputs:
  %
  % i)   variable from workspace (pass w/o single quotes)
  % ii)  a file name (*.mat, *.nii, *.nii.gz)
  % iii) a directory ('/../MaskFolder')
  %
  % (i) and (ii) loads the target mask (binary or labeled).
  %
  % (iii) loads the file (*.mat, *.nii, *.nii.gz) directly if it
  % is the only only file respecting the format.
  % If there are multiple files, (iii) assumes that the directory
  % contains a collection of binary masks, reads them all and merges
  % into a single labeled mask, where regions are labeled by the
  % respective file names.
  %
  % Warning for (iii): Please make sure that binary masks have no
  % overlapping regions, if multiple binary masks are going to be
  % read.

  % Developers:
  % Overridden superclass method to load StatMask into both
  % objects simultaneously if the whole object array is passed.
  %
  % Individual objects can load masks as well. qmrstat.validation
  % will take care of it.

  W = evalin('caller','whos');

  if ~isempty(ismember(inputname(2),[W(:).name])) && all(ismember(inputname(2),[W(:).name]))


    if length(obj) ==2

      obj(1) = loadStatMask@AbstractStat(obj(1),input);
      obj(2) = loadStatMask@AbstractStat(obj(2),input);

    elseif length(obj) ==1

      obj = loadStatMask@AbstractStat(obj,input);
    end

  else


    if length(obj) ==2

      obj(1) = loadStatMask@AbstractStat(obj(1),eval('input'));
      obj(2) = loadStatMask@AbstractStat(obj(2),eval('input'));

    elseif length(obj) ==1

      obj = loadStatMask@AbstractStat(obj,eval('input'));

    end

  end




end

function obj = setSignificanceLevel(obj,in)


  args = num2cell(in);
  [obj(:).SignificanceLevel] = deal(args{:});


end

function obj = setFigureOption(obj,in)

  if ~isequal(in,'osd') && ~isequal(in,'save') && ~isequal(in,'disable')

    error( [obj.ErrorHead...
    '\n>>>>>> FigureOption must be one of the following'...
    '\n>>>>>> ''osd''     : On screen display mode.'...
    '\n>>>>>> ''save''    : Saves figure in Results.figure '...
    '\n>>>>>> ''disable'' : Nothing will be displayed.'...
    obj.Tail],'Correlation');


  end

  [obj(:).FigureOption] = deal({in});


end




end % END PUBLIC METHODS
% ===============================================================
end % END CLASSDEF
