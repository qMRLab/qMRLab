function [xl,y_bfl] = lsline_octave(X,Y,axsh)

xl = get(axsh,'xlim');
yl = get(axsh,'ylim');
pf = polyfit(X,Y,1);
y_bfl = pf(1)*xl + pf(2);
hold on;
plot(xl,y_bfl,'r','LineWidth',4);
set(axsh,'xlim',xl);
set(axsh,'ylim',yl);

end
