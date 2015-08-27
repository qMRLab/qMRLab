function width = fwhm(x,y)
% Full-Width at Half-Maximum (FWHM) of the waveform y(x)
% The FWHM result in 'width' will be in units of 'x'
% Rev 1.2, April 2006 (Patrick Egan)


y = y / max(y);
N = length(y);
lev50 = 0.5;
[~,centerindex]=max(abs(y));
i = 2;

%first crossing is between v(i-1) & v(i)
while sign(y(i)-lev50) == sign(y(i-1)-lev50)
    i = i+1;
end                                   
interp = (lev50-y(i-1)) / (y(i)-y(i-1));
tlead = x(i-1) + interp*(x(i)-x(i-1));

i = centerindex+1;   
%start search for next crossing at center
while ((sign(y(i)-lev50) == sign(y(i-1)-lev50)) && (i <= N-1))
    i = i+1;
end

if i ~= N
    interp = (lev50-y(i-1)) / (y(i)-y(i-1));
    ttrail = x(i-1) + interp*(x(i)-x(i-1));
    width = ttrail - tlead;
else
    width = NaN;
end
