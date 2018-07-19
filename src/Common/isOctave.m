function retval = isOctave
%% ISOCTAVE
% Return: true if the environment is Octave.

    persistent cacheval;  % speeds up repeated calls

  if isempty (cacheval)
    cacheval = (exist ("OCTAVE_VERSION", "builtin") > 0);
  end

  retval = cacheval;
end