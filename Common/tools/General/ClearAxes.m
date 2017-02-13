function ClearAxes(handles)
cla(handles.SimCurveAxe1);
cla(handles.SimCurveAxe2);
cla(handles.SimCurveAxe);
cla(handles.SimVaryAxe);
cla(handles.SimRndAxe);
h = findobj(gcf,'Type','axes','Tag','legend');
delete(h);