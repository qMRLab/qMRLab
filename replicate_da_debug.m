for ii = 5:5:180
    theta = ii;
    phi = linspace(-pi, pi, 61);

    Mx = -cosd(theta).^2.*sind(theta).*sin(phi)+sind(2*theta).*cosd(theta).*cos(phi);
    My = sind(theta).*(cos(phi).^2-cosd(2*theta).*sin(phi).^2)+sind(2*theta)*cosd(theta)*sin(phi);
    figure()
    plot(Mx)
    hold on
    plot(My)
    hold off
    intMx = sum(Mx);

    intMy = sum(My);


    sig(ii)=sqrt(intMx.^2 + intMy.^2)./(2*pi);
end