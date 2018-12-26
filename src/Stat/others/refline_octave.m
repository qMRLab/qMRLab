function y = refline_octave(slope,intercept,axsh,color,wdth)

y = struct();
oldy = get(axsh,'ylim');
y.XData = get(axsh,'xlim');
y.YData = intercept + slope.*xl;
plot(y.xData,y.yData,color,'LineWidth',wdth);
set(axsh,'xlim',y.XData);
set(axsh,'ylim',oldy);

end
