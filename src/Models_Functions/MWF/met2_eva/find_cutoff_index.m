function [index, new_cutoff] = find_cutoff_index(cutoff, t2_vals)
%-----------------------------------------------------------------------------------
%
%  [index, new_cutoff] = find_cutoff_index(cutoff, t2_vals)
%
%  Function to find index corresponding to closest T2 value to cutoff in range
%
%	Ives Levesque, Feb 2007
%
%-----------------------------------------------------------------------------------


if cutoff > max(t2_vals) | cutoff < min(t2_vals)
   error('Cutoff value not in range.')
end

index = find(t2_vals==cutoff);

if isempty(index)
    temp_index = max(find(t2_vals<cutoff));
    if abs(t2_vals(temp_index+1)-cutoff) < abs(t2_vals(temp_index)-cutoff)
        index = temp_index + 1;
    else
        index = temp_index;
    end
end

new_cutoff = t2_vals(index);


%-----------------------------------------------------------------------------------
