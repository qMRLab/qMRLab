function T2 = getT2(obj,EchoTimes)
    T2.num = 120;
    switch obj.options.RelaxationType
        case 'T2'
            T2.range = [1.5*EchoTimes(1), 400]; % Kolind et al. doi: 10.1002/mrm.21966
        case 'T2star'
            T2.range = [1.5*EchoTimes(1), 300]; % Lenz et al. doi: 10.1002/mrm.23241
            %             T2_range = [1.5*echo_times(1), 600]; % Use this to look at CSF component
    end
    T2.vals = T2.range(1)*(T2.range(2)/T2.range(1)).^(0:(1/(T2.num-1)):1)';
end