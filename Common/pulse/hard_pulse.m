function pulse = hard_pulse(t,Trf,~)

pulse = single(~(t < 0 | t>Trf));
