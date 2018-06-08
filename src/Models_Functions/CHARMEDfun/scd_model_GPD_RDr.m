function RDr=scd_model_GPD_RDr(d,Delta,delta,Dr)
% RDr=scd_model_GPD_RDr(d,Delta,delta,Dr)

alpha=4*delta*Dr/d^2; beta=4*Delta*Dr/d^2;
a=[1.84118378134065	5.33144277352503	8.53631636634628	11.7060049025920	14.8635886339090].^2;% roots of bessel J1'
td=Delta-delta/3;

k=zeros(length(delta),5);
for m=1:5;
    numerator=2*alpha*a(m) - 2 + 2*exp(-alpha*a(m)) + (2-exp(alpha*a(m))-exp(-alpha*a(m))).*exp(-beta*a(m));
    denominator=alpha.^2*a(m).^3.*(a(m)-1);
    k(:,m)=numerator(:)./denominator(:);
end
k(isnan(k))=0;
RDr=sum(k,2).*d.^2./(2*td);