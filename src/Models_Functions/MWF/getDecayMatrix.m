function DecayMatrix = getDecayMatrix(EchoTimes,T2vals)
    DecayMatrix = zeros(length(EchoTimes),length(T2vals));
    for j = 1:length(T2vals)
        DecayMatrix(:,j) = exp(-EchoTimes/T2vals(j))';
    end
end
