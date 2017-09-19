function bvalues=scd_scheme_bvalue(scheme)
gyro = 42.57; % kHz/mT
scheme(:,8) = gyro*scheme(:,4).*scheme(:,6); % um-1
bvalues=(2*pi*scheme(:,8)).^2.*(scheme(:,5)-scheme(:,6)/3);
end