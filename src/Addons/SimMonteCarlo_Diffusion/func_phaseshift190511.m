function phaseshift = func_phaseshift190511(position, G, axis, time)
    
    % G[mT/m]
    % time[ms]
    % position[um]
    % axis ->unit vector

    larmor = 2*pi*42.58; % [radian/(mT*ms)]
    magnet = (position*squeeze(axis)).*G* 10^-6; % [mT]
    %fprintf('position -> %g[um], magnet = %g [mT], ratio = %g\n',position(1), magnet, magnet/position(1));
    
    phaseshift = larmor * magnet * time; %[radian]

