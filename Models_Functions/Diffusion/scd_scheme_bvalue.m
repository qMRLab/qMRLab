function bvalues=scd_scheme_bvalue(scheme)
    bvalues=(2*pi*scheme(:,8)).^2.*(scheme(:,5)-scheme(:,6)/3);
end