function w1cw = compute_w1cw(TR, Pulse)
%compute_w1cw Compute the constant wave equivalent power over a period TR for a given pulse

w1cw = zeros(length(Pulse),1);

for ii = 1:length(Pulse)
    Trf = Pulse(ii).Trf;
    omega2 = Pulse(ii).omega2;
    int = integral(omega2, 0, Trf,'ArrayValued',true);
    w1cw(ii) = sqrt( int / TR );
end

end

