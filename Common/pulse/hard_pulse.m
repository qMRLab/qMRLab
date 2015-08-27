function pulse = hard_pulse(t,Trf,~)

pulse = ~(t < 0 | t>Trf);
