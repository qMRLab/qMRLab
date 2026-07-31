function Sfi = GetSf(angles, offsets, T2f, SfTable)
%GetSf interpolate Sf values from precomputed table

% One-entry memo.
%
% Sfi is a pure function of (angles, offsets, T2f, SfTable). Under lsqcurvefit
% the Jacobian is built by finite differences that perturb one parameter at a
% time, so most consecutive calls within an iteration leave T2f untouched and
% would otherwise repeat an identical interpolation.
%
% angles and offsets already carry the per-voxel B1 scaling and B0 shift
% (SPGR_fit does Prot.Angles = Prot.Angles * FitOpt.B1 and
% Prot.Offsets = Prot.Offsets + FitOpt.B0), so a voxel with different B1/B0
% keys differently and correctly misses. Comparisons are ordered cheapest-first
% so a miss short-circuits before reaching the vector compares.
%
% The table is fingerprinted rather than compared: a rebuild at the same
% protocol would otherwise be invisible to the key.
persistent kAngles kOffsets kT2f kFingerprint kSfi

fingerprint = [numel(SfTable.values), SfTable.values(1), SfTable.values(end)];
if ~isempty(kSfi) && isequal(T2f, kT2f) && isequal(fingerprint, kFingerprint) ...
        && isequal(angles, kAngles) && isequal(offsets, kOffsets)
    Sfi = kSfi;
    return
end

printed = false;

% This is a little workspace trick to limit the number of
% Sf table interpolation warnings to the command window/console.
% If the counterSfMiss variable exists in the base workspace,
% its value will nbe subjected to evaluation. If not, will be assigned
% with 0 and broadcasted to the base workspace.
% This is not a go-to *.m practice, especially if done without enough
% comments.

% Interpolate every (angle, offset) pair in a single call. interp3 evaluates
% each query point independently, so this is the same trilinear arithmetic the
% per-point loop performed -- it just pays interp3's dispatch and the meshgrid
% construction once instead of once per angle.
n = numel(angles);
Sfi = interp3(SfTable.offsets, SfTable.angles, SfTable.T2f, SfTable.values, ...
              offsets(:), angles(:), repmat(T2f, n, 1));

% Any query outside the table interpolates to NaN; fall back to computing it.
for ii = find(isnan(Sfi(:)))'

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

kAngles = angles; kOffsets = offsets; kT2f = T2f;
kFingerprint = fingerprint; kSfi = Sfi;
