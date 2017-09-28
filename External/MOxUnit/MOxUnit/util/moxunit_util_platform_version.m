function v=moxunit_util_platform_version()
% return the version of Matlab or Octave
%
% v=moxunit_util_platform_version()
%
% Output:
%   v               Vector with two (Matlab) or three (Octave) elements,
%                   for example 8.5 (for Matlab) or 4.0.3) for Octave)
%


    version_str=version();

    parts=regexp(version_str,'\s','split');
    first_part=parts{1};

    num_parts=regexp(first_part,'\.','split');
    v=cellfun(@str2num,num_parts);



