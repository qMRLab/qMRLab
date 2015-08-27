function y = sinc(x)

if (x < 0.001)
    y = 1;
else
    y = (sin(pi*x))./(pi*x);
end

ii = isnan(y);
y(ii) = 1;

end