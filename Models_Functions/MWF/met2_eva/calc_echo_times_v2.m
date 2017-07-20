function echo_times = calc_echo_times_v2(num_echoes,Echo)
%*************************************************************************
% SPECIAL VERSION adapted for qMRLab
% By Ian Gagnon, 2017
% For the original version, see calc_echo_times.m
% *************************************************************************
% Caculate echo times
    echo_times(1) = Echo.First;
    ES = Echo.Spacing;
    echo_times(2:num_echoes)=echo_times(1)+ES*(1:num_echoes-1);
end