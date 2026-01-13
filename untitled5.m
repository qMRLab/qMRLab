close all
clear all
clc

Fs = 100;            % Sampling frequency                    
T = 1/Fs;             % Sampling period       
L = 5000;             % Length of signal
t = (0:L-1)*T;        % Time vector

x = sin(t-(L-1)*T/2)./(t-(L-1)*T/2);

plot(t, x)

figure()

f = Fs*(-L/2:(L/2))/L;

f(end)=[]

Y = fft(x);

plot(f,abs(Y)) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')