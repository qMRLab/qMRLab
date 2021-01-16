function Sfi = GetSf(angles, offsets, T2f, SfTable)
%GetSf interpolate Sf values from precomputed table

Sfi = zeros(length(angles),1);
printed = false;

% This is a little workspace trick to limit the number of 
% Sf table interpolation warnings to the command window/console. 
% If the counterSfMiss variable exists in the base workspace, 
% its value will nbe subjected to evaluation. If not, will be assigned
% with 0 and broadcasted to the base workspace. 
% This is not a go-to *.m practice, especially if done without enough 
% comments.


for ii = 1:length(angles)
   
[xi, yi, zi] = meshgrid(offsets(ii), angles(ii), T2f);
Sfi(ii) = interp3(SfTable.offsets, SfTable.angles, SfTable.T2f, SfTable.values, xi, yi, zi);

    if (isnan(Sfi(ii)))
        
        if ~evalin('base','exist(''counterSfMiss'')')
          counterSfMiss = 0;
          assignin('base','counterSfMiss',counterSfMiss);
         else
         counterSfMiss  = evalin('base','counterSfMiss');
      
        % Print this once for all the angles. Allow 10 global prints in total.
        % Fetch the variable from workspace. Doing this here instead of L14
        % means one less condition, which matters when there are thousands.

        if ~printed && counterSfMiss < 11
         % Get value from base kspace.   
          cprintf('magenta','Cannot interpolate value from current Sf table : angle: %f; offset: %f; T2f: %f\n',angles(ii), offsets(ii), T2f);
          cprintf('blue','%s','Calculating the missing Sf value...');
          if counterSfMiss==10
            cprintf('blue','%s','Remaining warnings for missing Sf value interpolations have been silenced for this processs');
          end
          counterSfMiss = counterSfMiss + 1;
          assignin('base','counterSfMiss',counterSfMiss);
          printed = true;
        end
        
        end 
        
        MTpulse = GetPulse(angles(ii),offsets(ii),SfTable.PulseTrf,SfTable.PulseShape,SfTable.PulseOpt);
        Sfi(ii) = computeSf(T2f, MTpulse);
    end
end