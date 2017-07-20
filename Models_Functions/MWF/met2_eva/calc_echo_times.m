function echo_times = calc_echo_times(num_echoes)
%
% caculate echo times
nseq = input('Does the data acquisition use one (1) or two (2) sequences?: ');
if nseq == 1
    echo_times(1)=input('Enter the first echo time in ms: ');
    ES=input('Enter the echo spacing in ms: ');
    
    echo_times(2:num_echoes)=echo_times(1)+ES*(1:num_echoes-1);
elseif nseq == 2
    echo_times(1)=input('Enter the first echo time in ms for sequence 1: ');
    s1ES=input('Enter the echo spacing in ms for sequence 1: ');
    echo_times(2)=input('Enter the first echo time in ms for sequence 2: ');
    s2ES=input('Enter the echo spacing in ms for sequence 2: ');    
    
    echo_times(3:2:num_echoes-1)=echo_times(1)+s1ES*(1:((num_echoes/2)-1));
    echo_times(4:2:num_echoes)=echo_times(2)+s2ES*(1:((num_echoes/2)-1));
end

end