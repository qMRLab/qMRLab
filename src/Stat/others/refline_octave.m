function y = refline_octave(slope,intercept,axsh,color,wdth)

y = struct();
oldy = get(axsh,'ylim');
y.XData = get(axsh,'xlim');
y.YData = intercept + slope.*y.XData;
hold on
plot(y.XData,y.YData,color,'LineWidth',wdth);
set(axsh,'xlim',y.XData);
set(axsh,'ylim',oldy);

end
