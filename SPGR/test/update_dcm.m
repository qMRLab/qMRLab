function txt = update_dcm(empt,event_obj)
% Customizes text of data tips

pos = get(event_obj,'Position');
txt = {['Time: ',num2str(pos(1))],...
	      ['Amplitude: ',num2str(pos(2))]};