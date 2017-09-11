function x0 = addfixparameters(x0,x,fixedparam)
x0(~fixedparam) = x;
end
